import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/lecture.dart';

/// Schedule-level state, derived purely from the clock — except
/// [completed], which additionally requires that at least one student
/// was actually marked present/late. A lecture whose end time has passed
/// with zero present/late records was never actually conducted (nobody
/// took attendance, or it was cancelled) — that's [notConducted], kept
/// distinct from a lecture that genuinely ran.
enum _LectureState { upcoming, ongoing, completed, notConducted }

DateTime _combine(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String _pad2(int n) => n.toString().padLeft(2, '0');

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  if (DateUtils.isSameDay(date, now)) return "Today";
  if (DateUtils.isSameDay(date, now.add(const Duration(days: 1)))) return "Tomorrow";
  if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) return "Yesterday";
  return DateFormat("EEE, d MMM").format(date);
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusInfo(this.label, this.color, this.icon);
}

/// Shows a lecture with a live status badge.
///
/// Schedule state (upcoming/ongoing/completed) is derived from
/// `DateTime.now()` vs the lecture's real start/end time, not the stale
/// `status` field on the lecture doc (written once at creation, never
/// updated). "Completed" additionally requires at least one present/late
/// attendance record class-wide — a lecture whose time simply elapsed
/// with nobody marked shows as "Not conducted" instead, since the clock
/// alone can't tell "class happened" from "class never started."
///
/// Once a lecture is genuinely completed, pass [studentId] to show this
/// student's own outcome — Present / Late / Absent — read from the
/// lecture's `attendance` list, separately from the class-wide check
/// above.
class UpcomingClassCard extends StatefulWidget {
  final LectureModel lectureModel;
  final String? studentId;

  const UpcomingClassCard({
    super.key,
    required this.lectureModel,
    this.studentId,
  });

  @override
  State<UpcomingClassCard> createState() => _UpcomingClassCardState();
}

class _UpcomingClassCardState extends State<UpcomingClassCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Re-evaluate periodically so a card flips upcoming -> ongoing ->
    // completed live while it's on screen, without needing the parent
    // list to rebuild.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
//room
  DateTime get _start =>
      _combine(widget.lectureModel.dated, widget.lectureModel.start_time);
  DateTime get _end =>
      _combine(widget.lectureModel.dated, widget.lectureModel.end_time);

  /// Whether *any* student was marked present or late for this lecture —
  /// the class-wide signal that it actually ran, independent of which
  /// student is viewing the card.
  bool get _classWasConducted {
    final attendance = widget.lectureModel.attendance ?? [];
    return attendance.any((a) => a.status == 'present' || a.status == 'late');
  }

  _LectureState get _state {
    final now = DateTime.now();
    if (now.isBefore(_start)) return _LectureState.upcoming;
    if (!now.isAfter(_end)) return _LectureState.ongoing;
    return _classWasConducted ? _LectureState.completed : _LectureState.notConducted;
  }

  /// This student's attendance status once the lecture has ended — null
  /// if no [studentId] was given, or no record exists yet.
  String? get _attendanceStatus {
    final studentId = widget.studentId;
    if (studentId == null) return null;
    final record = (widget.lectureModel.attendance ?? [])
        .firstWhereOrNull((a) => a.sid == studentId);
    return record?.status;
  }

  _StatusInfo _statusInfo(BuildContext context) {
    switch (_state) {
      case _LectureState.upcoming:
        return const _StatusInfo("Upcoming", Colors.blue, CupertinoIcons.clock);
      case _LectureState.ongoing:
        return const _StatusInfo("Ongoing", Colors.orange, CupertinoIcons.play_circle_fill);
      case _LectureState.notConducted:
        return const _StatusInfo("Not conducted", Colors.grey, CupertinoIcons.minus_circle);
      case _LectureState.completed:
        switch (_attendanceStatus) {
          case 'present':
            return _StatusInfo(
                "Present", Theme.of(context).primaryColor, CupertinoIcons.check_mark_circled_solid);
          case 'late':
            return const _StatusInfo("Late", Colors.brown, CupertinoIcons.clock_fill);
          case 'absent':
            return const _StatusInfo("Absent", Colors.red, CupertinoIcons.xmark_circle_fill);
          default:
          // Lecture was conducted, but there's no attendance record for
          // this student (or no studentId was passed at all).
            return const _StatusInfo("Not marked", Colors.grey, CupertinoIcons.question_circle);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lectureModel = widget.lectureModel;
    final status = _statusInfo(context);

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: status.color),
              Expanded(
                child: Container(
                  color: status.color.withOpacity(0.04),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              lectureModel.course,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(label: status.label, color: status.color, icon: status.icon),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: CupertinoIcons.calendar,
                            text: _dateLabel(lectureModel.dated),
                          ),
                          _InfoChip(
                            icon: CupertinoIcons.clock,
                            text: "${_pad2(lectureModel.start_time.hour)}:${_pad2(lectureModel.start_time.minute)}"
                                " - ${_pad2(lectureModel.end_time.hour)}:${_pad2(lectureModel.end_time.minute)}",
                          ),
                          if (lectureModel.room != null && lectureModel.room.isNotEmpty)
                            _InfoChip(
                              icon: CupertinoIcons.location_solid,
                              text: "room ${lectureModel.room}",
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}