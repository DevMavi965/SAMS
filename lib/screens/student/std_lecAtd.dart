import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/attendance.dart';
import '../../models/lecture.dart';
import '../../services/db_service.dart';
import '../../services/notification_helper.dart';

/// How long a student has, after checking in, to tap "Mark Midpoint"
/// before they're auto-marked absent for the lecture.
const Duration kMidpointWindow = Duration(minutes: 5);

/// Checkout is only allowed within this window around the lecture's
/// real end time: from 5 minutes before it to 5 minutes after it.
const Duration kCheckoutWindowBefore = Duration(minutes: 5);
const Duration kCheckoutWindowAfter = Duration(minutes: 5);

DateTime _combine(DateTime date, TimeOfDay time) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);

enum _LecState { upcoming, ongoing, completed }

/// Attendance-actions section meant to sit directly below
/// UpcomingClassCard for a given lecture/student pair.
///
/// - Ongoing lecture, no attendance record yet -> check-in buttons
///   (fingerprint / face ID).
/// - Ongoing lecture, checked in, midpoint not yet due/missed ->
///   midpoint button + a live countdown, backed by a scheduled local
///   notification reminding the student to tap it. If the midpoint
///   window elapses without a tap, the student's attendance flips to
///   "absent" and checkout becomes unavailable (studentCheckOut in
///   DbService already refuses to run unless mid_point == true).
/// - Ongoing lecture, midpoint done -> checkout button, enabled only
///   in the +/-5 minute window around the lecture's end time.
/// - Completed lecture -> a read-only timeline of whatever the
///   student actually did (checkin / midpoint / checkout), each line
///   shown only if that step happened; nothing rendered at all if the
///   student has no attendance record.
class LectureAttendanceSection extends StatefulWidget {
  const LectureAttendanceSection({
    super.key,
    required this.lectureModel,
    required this.studentId,
  });

  final LectureModel lectureModel;
  final String studentId;

  @override
  State<LectureAttendanceSection> createState() =>
      _LectureAttendanceSectionState();
}

class _LectureAttendanceSectionState extends State<LectureAttendanceSection> {
  Timer? _tick;
  Timer? _midpointDeadlineTimer;
  bool _autoAbsentFired = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Live-update the section every 15s so buttons enable/disable and
    // the countdown moves without needing a parent rebuild.
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
    _maybeArmMidpointDeadline();
  }

  @override
  void didUpdateWidget(covariant LectureAttendanceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeArmMidpointDeadline();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _midpointDeadlineTimer?.cancel();
    super.dispose();
  }

  DbService get _db => Provider.of<DbService>(context, listen: false);

  LectureModel get _lecture => widget.lectureModel;

  DateTime get _start => _combine(_lecture.dated, _lecture.start_time);
  DateTime get _end => _combine(_lecture.dated, _lecture.end_time);

  _LecState get _state {
    final now = DateTime.now();
    if (now.isBefore(_start)) return _LecState.upcoming;
    if (now.isAfter(_end)) return _LecState.completed;
    return _LecState.ongoing;
  }

  Attendance? get _myRecord => (_lecture.attendance ?? [])
      .firstWhereOrNull((a) => a.sid == widget.studentId);

  DateTime? _asDateTime(TimeOfDay? t) =>
      t == null ? null : _combine(_lecture.dated, t);

  /// Arms a one-shot in-app Timer for 5 minutes after checkin, and a
  /// local notification for the same moment, so the student is warned
  /// whether or not the app is in the foreground when the window
  /// closes.
  ///
  /// NOTE: this in-app timer only runs while this widget is mounted
  /// on the student's device. It's a reasonable client-side
  /// approximation, but it can't guarantee the absent-flip happens if
  /// the app is fully closed when the deadline passes. For a
  /// guarantee independent of the app being open, move this decision
  /// into a scheduled Cloud Function keyed off the same
  /// checkin + 5min deadline.
  void _maybeArmMidpointDeadline() {
    _midpointDeadlineTimer?.cancel();
    final record = _myRecord;
    if (record == null) return;
    if (record.mid_point == true) return;
    if (record.status == 'absent') return;

    final checkinAt = _asDateTime(record.checkin);
    if (checkinAt == null) return;
    final deadline = checkinAt.add(kMidpointWindow);

    // Schedule (once) the reminder notification for just before the deadline.
    NotifHelper.scheduledNotification(
      "midpoint",
      "Midpoint check-in",
      "Tap 'Mark Midpoint' for ${_lecture.course} in the next minute or you'll be marked absent.",
      deadline.subtract(const Duration(minutes: 1)),
    );

    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) {
      // Deadline already passed (e.g. screen reopened late).
      _fireAutoAbsentIfNeeded();
      return;
    }
    _midpointDeadlineTimer = Timer(remaining, _fireAutoAbsentIfNeeded);
  }

  Future<void> _fireAutoAbsentIfNeeded() async {
    if (_autoAbsentFired || !mounted) return;
    final record = _myRecord;
    if (record == null || record.mid_point == true || record.status == 'absent') {
      return;
    }
    _autoAbsentFired = true;
    await _db.markAbsentForMissedMidpoint(null, _lecture, widget.studentId);
    if (mounted) setState(() {});
  }

  bool get _inCheckoutWindow {
    final now = DateTime.now();
    return !now.isBefore(_end.subtract(kCheckoutWindowBefore)) &&
        !now.isAfter(_end.add(kCheckoutWindowAfter));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _LecState.upcoming:
        return const SizedBox.shrink();
      case _LecState.ongoing:
        return _buildOngoing(context);
      case _LecState.completed:
        return _buildCompleted(context);
    }
  }

  // ---- Ongoing ----

  Widget _buildOngoing(BuildContext context) {
    final record = _myRecord;

    if (record == null) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mark your attendance",
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.hand_raised_fill,
                    label: "Fingerprint",
                    busy: _busy,
                    onTap: () => _run(() => _db.studentCheckIn(
                        context, _lecture, widget.studentId, "fingerprint")),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.person_crop_circle_fill,
                    label: "Face ID",
                    busy: _busy,
                    onTap: () => _run(() => _db.studentCheckIn(
                        context, _lecture, widget.studentId, "facial")),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (record.status == 'absent') {
      return _card(
        child: const Text(
          "You missed the midpoint window and were marked absent for this lecture.",
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (record.mid_point != true) {
      final checkinAt = _asDateTime(record.checkin)!;
      final deadline = checkinAt.add(kMidpointWindow);
      final remaining = deadline.difference(DateTime.now());
      final remainingLabel = remaining.isNegative
          ? "expired"
          : "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')} left";

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Checked in at ${DateFormat.jm().format(checkinAt)}"),
            const SizedBox(height: 4),
            Text("Mark your midpoint — $remainingLabel",
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _ActionButton(
              icon: CupertinoIcons.checkmark_alt_circle_fill,
              label: "Mark Midpoint",
              busy: _busy,
              onTap: () =>
                  _run(() => _db.studentMidPoint(context, _lecture, widget.studentId)),
            ),
          ],
        ),
      );
    }

    // Midpoint done -> checkout gated to the +/-5 min window.
    if (record.checkout != null) {
      return _card(
        child: Text(
          "Checked out at ${DateFormat.jm().format(_asDateTime(record.checkout)!)}",
          style: const TextStyle(color: Colors.green),
        ),
      );
    }

    if (!_inCheckoutWindow) {
      final opensAt = _end.subtract(kCheckoutWindowBefore);
      return _card(
        child: Text(
          DateTime.now().isBefore(opensAt)
              ? "Checkout opens at ${DateFormat.jm().format(opensAt)}"
              : "Checkout window has closed",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Check out", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: CupertinoIcons.hand_raised_fill,
                  label: "Fingerprint",
                  busy: _busy,
                  onTap: () => _run(() => _db.studentCheckOut(
                      context, _lecture, widget.studentId, "fingerprint")),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: CupertinoIcons.person_crop_circle_fill,
                  label: "Face ID",
                  busy: _busy,
                  onTap: () => _run(() => _db.studentCheckOut(
                      context, _lecture, widget.studentId, "facial")),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Completed ----

  Widget _buildCompleted(BuildContext context) {
    final record = _myRecord;
    if (record == null) return const SizedBox.shrink(); // nothing done -> show nothing

    final rows = <Widget>[];
    final checkinAt = _asDateTime(record.checkin);
    if (checkinAt != null) {
      rows.add(_TimelineRow(
        icon: CupertinoIcons.arrow_right_circle_fill,
        label: "Checked in",
        time: DateFormat.jm().format(checkinAt),
      ));
      if (record.mid_point == true) {
        rows.add(const _TimelineRow(
          icon: CupertinoIcons.checkmark_alt_circle_fill,
          label: "Midpoint marked",
        ));
        final checkoutAt = _asDateTime(record.checkout);
        if (checkoutAt != null) {
          rows.add(_TimelineRow(
            icon: CupertinoIcons.arrow_left_circle_fill,
            label: "Checked out",
            time: DateFormat.jm().format(checkoutAt),
          ));
        }
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.busy,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: busy ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.icon, required this.label, this.time});

  final IconData icon;
  final String label;
  final String? time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(label),
          if (time != null) ...[
            const Spacer(),
            Text(time!, style: const TextStyle(color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}