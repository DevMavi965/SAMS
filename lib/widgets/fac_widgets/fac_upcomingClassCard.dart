import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/services/db_service.dart';

enum _LectureState { upcoming, ongoing, completed }

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

class FacUpcomingClassCard extends StatefulWidget {
  final LectureModel lectureModel;

  const FacUpcomingClassCard({
    super.key,
    required this.lectureModel,
  });

  @override
  State<FacUpcomingClassCard> createState() => _FacUpcomingClassCardState();
}

class _FacUpcomingClassCardState extends State<FacUpcomingClassCard> {
  Timer? _timer;

  // Created lazily, only once the lecture is completed, and cached so the
  // 30s setState doesn't recreate the stream (which would cause flicker).
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _indexDocStream;

  @override
  void initState() {
    super.initState();
    // Re-evaluate periodically so the card flips upcoming -> ongoing ->
    // completed live while on screen.
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

  // Purely time based.
  _LectureState get _state {
    final now = DateTime.now();
    if (now.isBefore(_start)) return _LectureState.upcoming;
    if (now.isBefore(_end)) return _LectureState.ongoing;
    return _LectureState.completed;
  }

  _StatusInfo _statusInfo() {
    switch (_state) {
      case _LectureState.upcoming:
        return const _StatusInfo("Upcoming", Colors.blue, CupertinoIcons.clock);
      case _LectureState.ongoing:
        return const _StatusInfo("Ongoing", Colors.orange, CupertinoIcons.play_circle_fill);
      case _LectureState.completed:
        return _StatusInfo("Completed", Theme.of(context).primaryColor,
            CupertinoIcons.check_mark_circled_solid);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _getIndexStream() {
    final id = widget.lectureModel.id;
    if (id == null) return null;
    return _indexDocStream ??= Provider.of<DbService>(context, listen: false)
        .indexDoc
        .doc(id)
        .snapshots() as Stream<DocumentSnapshot<Map<String, dynamic>>>;
  }

  int _count(String status) => (widget.lectureModel.attendance ?? [])
      .where((a) => a.status == status)
      .length;

  Widget _statsSection() {
    final stream = _getIndexStream();
    if (stream == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final finalized = snap.data?.data()?['attendance_finalized'] == true;
        if (!finalized) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatTile(
                    count: _count('present'),
                    label: "Present",
                    color: Theme.of(context).primaryColor,
                    icon: CupertinoIcons.check_mark_circled,
                  ),
                  _StatTile(
                    count: _count('late'),
                    label: "Late",
                    color: Colors.brown,
                    icon: CupertinoIcons.clock,
                  ),
                  _StatTile(
                    count: _count('absent'),
                    label: "Absent",
                    color: Colors.red,
                    icon: CupertinoIcons.xmark_circle,
                  ),
                  _StatTile(
                    count: _count('leave'),
                    label: "On Leave",
                    color: Colors.amber.shade700,
                    icon: PhosphorIconsBold.airplaneTakeoff,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lectureModel = widget.lectureModel;
    final status = _statusInfo();

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
                          if (lectureModel.room.isNotEmpty)
                            _InfoChip(
                              icon: CupertinoIcons.location_solid,
                              text: "room ${lectureModel.room}",
                            ),
                        ],
                      ),
                      if (_state == _LectureState.completed) _statsSection(),
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  final int count;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
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