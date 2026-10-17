import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/lecture.dart';

enum _LectureState { beforeJoin, upcoming, ongoing, ended, onLeave }

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

class UpcomingClassCard extends StatefulWidget {
  final LectureModel lectureModel;
  final String? studentId;
  final bool onLeave; // approved leave covers lecture
  final DateTime? enrolledAt; // student joined at

  const UpcomingClassCard({
    super.key,
    required this.lectureModel,
    this.studentId,
    this.onLeave = false,
    this.enrolledAt,
  });

  @override
  State<UpcomingClassCard> createState() => _UpcomingClassCardState();
}

class _UpcomingClassCardState extends State<UpcomingClassCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // refresh phase every 30s
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime get _start =>
      _combine(widget.lectureModel.dated, widget.lectureModel.start_time);
  DateTime get _end =>
      _combine(widget.lectureModel.dated, widget.lectureModel.end_time);

  // this student's own record status
  String? get _attendanceStatus {
    final studentId = widget.studentId;
    if (studentId == null) return null;
    final record = (widget.lectureModel.attendance ?? [])
        .firstWhereOrNull((a) => a.sid == studentId);
    return record?.status;
  }

  _LectureState get _state {
    // lecture before student joined
    final joined = widget.enrolledAt;
    if (joined != null && _start.isBefore(joined)) return _LectureState.beforeJoin;

    // leave overrides everything else
    if (widget.onLeave || _attendanceStatus == 'leave') return _LectureState.onLeave;

    final now = DateTime.now();
    if (now.isBefore(_start)) return _LectureState.upcoming;
    if (!now.isAfter(_end)) return _LectureState.ongoing;
    return _LectureState.ended;
  }

  _StatusInfo _statusInfo(BuildContext context) {
    switch (_state) {
      case _LectureState.beforeJoin:
        return const _StatusInfo("Before joining", Colors.grey, CupertinoIcons.minus_circle);
      case _LectureState.upcoming:
        return const _StatusInfo("Upcoming", Colors.blue, CupertinoIcons.clock);
      case _LectureState.ongoing:
        return const _StatusInfo("Ongoing", Colors.orange, CupertinoIcons.play_circle_fill);
      case _LectureState.onLeave:
        return const _StatusInfo("On Leave", Colors.blue, PhosphorIconsBold.calendarCheck);
      case _LectureState.ended:
        switch (_attendanceStatus) {
          case 'present':
            return _StatusInfo(
                "Present", Theme.of(context).primaryColor, CupertinoIcons.check_mark_circled_solid);
          case 'late':
            return const _StatusInfo("Late", Colors.brown, CupertinoIcons.clock_fill);
          default:
          // ended without attending
            return const _StatusInfo("Absent", Colors.red, CupertinoIcons.xmark_circle_fill);
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
                              RMFuncts.getSentenceCase(lectureModel.course),
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
                          if (lectureModel.room.isNotEmpty)
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