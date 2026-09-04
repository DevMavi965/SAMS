import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/services/geo_location_service.dart';

import '../../models/attendance.dart';
import '../../models/lecture.dart';
import '../../services/db_service.dart';
import '../../services/notification_helper.dart';

/// Checkout is only allowed within this window around the lecture's
/// real end time: from 5 minutes before it to 5 minutes after it.
const Duration kCheckoutWindowBefore = Duration(minutes: 5);
const Duration kCheckoutWindowAfter = Duration(minutes: 5);

/// How long the midpoint button stays visible once it opens, for a given
/// student. This is a hard 5-minute window -- miss it and you're marked
/// absent for the lecture.
const Duration kMidpointWindowDuration = Duration(minutes: 5);

/// Buffer kept clear at the start and end of the lecture so the window
/// can never open in the first/last 5 minutes.
const Duration kMidpointLectureBuffer = Duration(minutes: 5);

DateTime _combine(DateTime date, TimeOfDay time) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);

enum _LecState { upcoming, ongoing, completed }

/// Attendance-actions section meant to sit directly below
/// UpcomingClassCard for a given lecture/student pair.
///
/// - Ongoing lecture, no attendance record yet -> check-in buttons
///   (fingerprint / face ID).
/// - Ongoing lecture, checked in but this student's midpoint window has
///   not opened yet -> locked card showing when the button will become
///   available.
/// - Ongoing lecture, midpoint window is open -> midpoint button + a
///   countdown to when the window closes (opensAt + 5 min). Miss it and
///   attendance flips to "absent" automatically.
/// - Ongoing lecture, midpoint done -> checkout button, enabled only
///   in the +/-5 minute window around the lecture's end time.
/// - Completed lecture -> a read-only timeline of whatever the
///   student actually did (checkin / midpoint / checkout), each line
///   shown only if that step happened; nothing rendered at all if the
///   student has no attendance record.
///
/// **Midpoint timing rule**
/// Each student gets their own randomly-timed 5-minute window, chosen
/// once between [lectureStart + 5 min] and [lectureEnd − 10 min] (so the
/// 5-minute window itself never bleeds past lectureEnd − 5 min). The
/// instant is generated locally on the student's device the first time
/// it's needed and cached in on-device storage (SharedPreferences) --
/// nothing is written to Firestore and nothing is derived from a shared
/// seed, so two students in the same lecture never see the same window.
///
/// **Important**: the student must check in FIRST before the midpoint
/// button becomes available, even if their random window has already
/// opened.
class LectureAttendanceSection extends StatefulWidget {
  const LectureAttendanceSection({
    super.key,
    required this.lectureModel,
    required this.studentId, required this.insAdmin, required this.institute,
  });
  final InsAdmin insAdmin;
  final Institute institute;
  final LectureModel lectureModel;
  final String studentId;

  @override
  State<LectureAttendanceSection> createState() =>
      _LectureAttendanceSectionState();
}

class _LectureAttendanceSectionState extends State<LectureAttendanceSection> {
  Timer? _tick;
  Timer? _midpointDeadlineTimer;
  Timer? _midpointOpenTimer;
  bool _autoAbsentFired = false;
  bool _busy = false;

  // This student's locally-generated midpoint window for this lecture.
  // Null until loaded/generated, or permanently null if the lecture is
  // too short to fit a window at all.
  DateTime? _midpointOpensAt;
  DateTime? _midpointClosesAt;
  bool _midpointWindowReady = false;

  @override
  void initState() {
    super.initState();
    // Live-update the section every 15s so buttons enable/disable and
    // the countdown moves without needing a parent rebuild.
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
    _initMidpointWindow();
  }

  @override
  void didUpdateWidget(covariant LectureAttendanceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lectureModel.id != widget.lectureModel.id) {
      // Different lecture reused on the same widget instance -> fresh window.
      _midpointWindowReady = false;
      _midpointOpensAt = null;
      _midpointClosesAt = null;
      _initMidpointWindow();
    } else {
      // Same lecture, but attendance may have just changed (e.g. the
      // student just checked in) -> re-evaluate the auto-absent timer.
      _armAutoAbsentTimer();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _midpointDeadlineTimer?.cancel();
    _midpointOpenTimer?.cancel();
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

  String get _midpointPrefsKey =>
      "midpoint_window_${_lecture.id}_${widget.studentId}";

  /// Loads this student's local midpoint window from on-device storage,
  /// generating and persisting a fresh one the first time it's needed.
  Future<void> _initMidpointWindow() async {
    final earliestOpen = _start.add(kMidpointLectureBuffer);
    final latestOpen =
    _end.subtract(kMidpointLectureBuffer + kMidpointWindowDuration);

    if (!earliestOpen.isBefore(latestOpen)) {
      // Lecture too short for a midpoint window at all.
      if (mounted) setState(() => _midpointWindowReady = true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedMs = prefs.getInt(_midpointPrefsKey);
    DateTime opensAt;

    if (storedMs != null &&
        _isWithin(
          DateTime.fromMillisecondsSinceEpoch(storedMs),
          earliestOpen,
          latestOpen,
        )) {
      opensAt = DateTime.fromMillisecondsSinceEpoch(storedMs);
    } else {
      opensAt = _generateAndStore(prefs, earliestOpen, latestOpen);
    }

    if (!mounted) return;
    setState(() {
      _midpointOpensAt = opensAt;
      _midpointClosesAt = opensAt.add(kMidpointWindowDuration);
      _midpointWindowReady = true;
    });

    _scheduleMidpointNotifications();
    _armOpenTimer();
    _armAutoAbsentTimer();
  }

  bool _isWithin(DateTime v, DateTime start, DateTime end) =>
      !v.isBefore(start) && !v.isAfter(end);

  /// Draws a fresh, unseeded random instant in [earliestOpen, latestOpen]
  /// and caches it on-device so it's stable across rebuilds/restarts.
  /// Unseeded (unlike the old lecture-id-hash approach) so every student
  /// gets an independent draw -- no two students share a window.
  DateTime _generateAndStore(
      SharedPreferences prefs, DateTime earliestOpen, DateTime latestOpen) {
    final windowSeconds = latestOpen.difference(earliestOpen).inSeconds;
    final offsetSeconds = Random().nextInt(windowSeconds);
    final opensAt = earliestOpen.add(Duration(seconds: offsetSeconds));
    prefs.setInt(_midpointPrefsKey, opensAt.millisecondsSinceEpoch);
    return opensAt;
  }

  void _scheduleMidpointNotifications() {
    final opensAt = _midpointOpensAt;
    final closesAt = _midpointClosesAt;
    if (opensAt == null || closesAt == null) return;
    final now = DateTime.now();

    if (opensAt.isAfter(now)) {
      NotifHelper.scheduledNotification(
        "midpoint",
        "Midpoint check-in is open",
        "Tap 'Mark Midpoint' for ${_lecture.course} in the next 5 minutes or you'll be marked absent.",
        opensAt,
        401,
      );
    }

    final reminderAt = closesAt.subtract(const Duration(minutes: 1));
    if (reminderAt.isAfter(now)) {
      NotifHelper.scheduledNotification(
        "midpoint",
        "Midpoint check-in closing soon",
        "1 minute left to tap 'Mark Midpoint' for ${_lecture.course}.",
        reminderAt,
        400,
      );
    }
  }

  /// Fires a rebuild right when the window opens, so the locked card
  /// clears promptly instead of waiting for the next 15s tick.
  void _armOpenTimer() {
    _midpointOpenTimer?.cancel();
    final opensAt = _midpointOpensAt;
    if (opensAt == null) return;
    final remaining = opensAt.difference(DateTime.now());
    if (remaining.isNegative) return;
    _midpointOpenTimer = Timer(remaining, () {
      if (mounted) setState(() {});
    });
  }

  /// Arms a one-shot in-app Timer that fires when this student's window
  /// closes and marks them absent if they haven't tapped the midpoint
  /// button by then.
  ///
  /// NOTE: this in-app timer only runs while this widget is mounted on
  /// the student's device. It's a reasonable client-side approximation,
  /// but it can't guarantee the absent-flip happens if the app is fully
  /// closed when the window closes. For a guarantee independent of the
  /// app being open, move this decision into a scheduled Cloud Function
  /// keyed off the same deadline.
  void _armAutoAbsentTimer() {
    _midpointDeadlineTimer?.cancel();
    final record = _myRecord;
    final closesAt = _midpointClosesAt;
    if (record == null || closesAt == null) return;
    if (record.mid_point == true) return;
    if (record.status == 'absent') return;
    if (_asDateTime(record.checkin) == null) return;

    final remaining = closesAt.difference(DateTime.now());
    if (remaining.isNegative) {
      _fireAutoAbsentIfNeeded();
      return;
    }
    _midpointDeadlineTimer = Timer(remaining, _fireAutoAbsentIfNeeded);
  }

  Future<void> _fireAutoAbsentIfNeeded() async {
    if (_autoAbsentFired || !mounted) return;
    final record = _myRecord;
    // Only fire if the student checked in but missed the midpoint
    if (record == null ||
        record.mid_point == true ||
        record.status == 'absent' ||
        _asDateTime(record.checkin) == null) {
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

    // --- Case 1: No attendance record yet -> Show check-in buttons ---
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
                    onTap: () {
                      if(GeofenceService.validateGeofence(
                          context: context,
                          targetLatitude: widget.institute.location['lat'],
                          targetLongitude: widget.institute.location['long']
                      )){
                        _run(() => _db.studentCheckIn(
                          //
                            context, _lecture, widget.studentId, "fingerprint"));
                      }
                    }
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.person_crop_circle_fill,
                    label: "Face ID",
                    busy: _busy,
                    onTap: () {

                      if(GeofenceService.validateGeofence(
                          context: context,
                          targetLatitude: widget.institute.location['lat'],
                          targetLongitude: widget.institute.location['long']
                      )){
                        _run(() => _db.studentCheckIn(
                            context, _lecture, widget.studentId, "facial")
                        );
                      }
                    }
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // --- Case 2: Student was marked absent ---
    if (record.status == 'absent') {
      return _card(
        child: const Text(
          "You missed the midpoint window and were marked absent for this lecture.",
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    // --- Case 3: Midpoint not yet marked ---
    if (record.mid_point != true) {
      if (!_midpointWindowReady) {
        return _card(
          child: const SizedBox(
            height: 24,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      }

      final checkinAt = _asDateTime(record.checkin);
      final opensAt = _midpointOpensAt;
      final closesAt = _midpointClosesAt;
      final now = DateTime.now();

      // Guard: lecture window too short to have a midpoint slot
      if (opensAt == null || closesAt == null) {
        return _card(
          child: const Text(
            "Lecture is too short for a midpoint check.",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      final bool hasCheckedIn = checkinAt != null;
      final bool isMidpointWindowOpen =
          !now.isBefore(opensAt) && now.isBefore(closesAt);
      final bool canMarkMidpoint = hasCheckedIn && isMidpointWindowOpen;

      // --- Phase 1: student hasn't checked in, window not yet open, or
      // window already closed (and the auto-absent timer hasn't caught
      // up yet) ---
      if (!canMarkMidpoint) {
        String message;
        IconData iconData;
        Color iconColor;

        if (!hasCheckedIn) {
          message = "Check in first to access midpoint";
          iconData = CupertinoIcons.hand_raised_slash;
          iconColor = Colors.grey;
        } else if (now.isBefore(opensAt)) {
          message = "Midpoint opens at ${DateFormat.jm().format(opensAt)}";
          iconData = CupertinoIcons.lock_fill;
          iconColor = Colors.grey;
        } else {
          // now is at/after closesAt -- window has closed.
          message = "Midpoint window has closed";
          iconData = CupertinoIcons.lock_fill;
          iconColor = Colors.grey;
        }

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCheckedIn)
                Text("Checked in at ${DateFormat.jm().format(checkinAt!)}"),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(iconData, size: 14, color: iconColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: iconColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: CupertinoIcons.checkmark_alt_circle_fill,
                label: "Mark Midpoint",
                busy: true, // disabled outside the open window
                onTap: () {},
              ),
            ],
          ),
        );
      }

      // --- Phase 2: window is open AND student has checked in ---
      // Show countdown to when the window closes.
      final remaining = closesAt.difference(now);
      final remainingLabel = remaining.isNegative
          ? "expired"
          : "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')} left";

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Checked in at ${DateFormat.jm().format(checkinAt!)}"),
            const SizedBox(height: 4),
            Text(
              remaining.isNegative
                  ? "Midpoint window expired — awaiting absent update…"
                  : "Mark midpoint — $remainingLabel",
              style: TextStyle(
                color: remaining.isNegative ? Colors.red : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: CupertinoIcons.checkmark_alt_circle_fill,
              label: "Mark Midpoint",
              busy: _busy || remaining.isNegative,
              onTap: () =>
                  _run(() => _db.studentMidPoint(context, _lecture, widget.studentId)),
            ),
          ],
        ),
      );
    }

    // --- Case 4: Midpoint done -> Show checkout ---

    // Already checked out
    if (record.checkout != null) {
      return _card(
        child: Text(
          "Checked out at ${DateFormat.jm().format(_asDateTime(record.checkout)!)}",
          style: const TextStyle(color: Colors.green),
        ),
      );
    }

    // Checkout window not yet open or already closed
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

    // Checkout window is open -> Show checkout buttons
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