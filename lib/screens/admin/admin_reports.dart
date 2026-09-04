import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../models/admin_model.dart';
import '../../services/db_service.dart';
import '../../widgets/admin_widgets/admin_custom_lineCart.dart';

class AdminReports extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Admin admin;
  const AdminReports({super.key, required this.admin, required this.insAdmin, required this.institute});

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  late final CollectionReference departmentsRef;
  late final CollectionReference indexDocRef;
  late final _AttendanceAggregator _aggregator;

  static const weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  static const List<Color> palette = [
    Color.fromARGB(255, 0, 153, 136),
    Color(0xFFFF6B6B),
    Color(0xFFFFB84C),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
    Color(0xFF38BDF8),
    Color(0xFFF472B6),
  ];

  // true = group analytics by semester, false = group by session
  bool _semesterView = true;

  // which department card is expanded, if any
  String? _expandedDeptId;

  @override
  void initState() {
    super.initState();
    final db = Provider.of<DbService>(context, listen: false);
    indexDocRef = db.indexDoc;
    departmentsRef = db.dbref
        .collection("ins_admins").doc(widget.admin.insAdminId)
        .collection("institutes").doc(widget.admin.instituteId)
        .collection("departments");

    _aggregator = _AttendanceAggregator(
      db: db,
      insAdminId: widget.admin.insAdminId!,
      instituteId: widget.admin.instituteId!,
    )..start();
  }

  @override
  void dispose() {
    _aggregator.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> get _studentIndexStream => indexDocRef
      .where("institute_id", isEqualTo: widget.admin.instituteId)
      .where("role", isEqualTo: "student")
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: departmentsRef.snapshots(),
        builder: (context, deptSnap) {
          if (!deptSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final departments = deptSnap.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: _studentIndexStream,
            builder: (context, studentSnap) {
              final Map<String, int> studentCounts = {};
              int totalStudents = 0;
              if (studentSnap.hasData) {
                for (final doc in studentSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final deptId = data['department_id']?.toString() ?? 'unknown';
                  studentCounts[deptId] = (studentCounts[deptId] ?? 0) + 1;
                  totalStudents++;
                }
              }

              return StreamBuilder<void>(
                stream: _aggregator.updates,
                builder: (context, _) {
                  if (!_aggregator.hasLoadedOnce) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final deptStats = _aggregator.computeDepartmentStats();
                  final weekly = _aggregator.computeWeeklyPercentages();
                  final overallPercent = _aggregator.computeOverallPercentage();
                  final conductedCount = _aggregator.computeConductedLectureCount();
                  final todayStats = _aggregator.computeTodayStats();

                  final deptRows = <Map<String, dynamic>>[
                    for (final d in departments)
                      {
                        "id": d.id,
                        "name": (d.data() as Map)['name']?.toString() ?? "Unnamed",
                        "attendence": (deptStats[d.id]?.percentage ?? 0).round(),
                        "total_students": studentCounts[d.id] ?? 0,
                      }
                  ]..sort((a, b) => (b["attendence"] as int).compareTo(a["attendence"] as int));

                  final groupStats = _semesterView
                      ? _aggregator.computeSemesterStats()
                      : _aggregator.computeSessionStats();

                  final groupRows = <_AnalyticsRow>[
                    for (final entry in groupStats.entries)
                      _AnalyticsRow(
                        id: entry.key,
                        label: _semesterView
                            ? _aggregator.semesterShortLabel(entry.key)
                            : _aggregator.sessionName(entry.key),
                        subtitle: _semesterView ? _aggregator.sessionNameForSemester(entry.key) : "",
                        percent: entry.value.percentage,
                      )
                  ]..sort((a, b) => _semesterView
                      ? _aggregator.semesterSortKey(a.id).compareTo(_aggregator.semesterSortKey(b.id))
                      : a.label.compareTo(b.label));

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return ListView(
                        padding: const EdgeInsets.all(15),
                        children: [
                          const Text("Reports & Analytics",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text("Live overview of attendance across your institute",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 18),

                          _buildStatGrid(
                            width: constraints.maxWidth,
                            departmentCount: departments.length,
                            studentCount: totalStudents,
                            overallPercent: overallPercent,
                            conductedCount: conductedCount,
                            todayPresent: todayStats['present']!,
                            todayTotal: todayStats['total']!,
                          ),
                          const SizedBox(height: 20),

                          AdminCustomLinechart(
                            days: weekdayLabels,
                            daily_attendance_percentage: weekly,
                          ),
                          const SizedBox(height: 20),

                          // --- Replaces "Department Performance" bar chart ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Attendance Analytics",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              _ViewToggle(
                                semesterView: _semesterView,
                                onChanged: (v) => setState(() => _semesterView = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _semesterView
                                ? "Attendance % across every semester with recorded lectures"
                                : "Attendance % across every academic session",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          groupRows.isEmpty
                              ? const _CardEmpty(label: "No lectures conducted yet")
                              : _GroupedAnalyticsChart(rows: groupRows, palette: palette),
                          const SizedBox(height: 24),

                          // --- Replaces flat "All Departments" list ---
                          const Text("Departments",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text("Tap a department for a full breakdown",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 10),

                          if (deptRows.isEmpty)
                            const _CardEmpty(label: "No departments yet")
                          else
                            for (final row in deptRows)
                              _DepartmentDetailCard(
                                key: ValueKey(row["id"]),
                                name: row["name"],
                                totalStudents: row["total_students"],
                                percent: row["attendence"],
                                expanded: _expandedDeptId == row["id"],
                                onTap: () => setState(() {
                                  _expandedDeptId =
                                  _expandedDeptId == row["id"] ? null : row["id"];
                                }),
                                breakdown: _aggregator.computeDepartmentBreakdown(row["id"]),
                                trend: _aggregator.computeDeptWeeklyTrend(row["id"]),
                                weekdayLabels: weekdayLabels,
                              ),

                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatGrid({
    required double width,
    required int departmentCount,
    required int studentCount,
    required double overallPercent,
    required int conductedCount,
    required int todayPresent,
    required int todayTotal,
  }) {
    final cards = <Widget>[
      _StatCard(icon: Icons.apartment_rounded, label: "Departments", value: "$departmentCount"),
      _StatCard(icon: Icons.school_rounded, label: "Students", value: "$studentCount"),
      _StatCard(
        icon: Icons.today_rounded,
        label: "Today's Attendance",
        value: todayTotal == 0 ? "—" : "$todayPresent/$todayTotal",
      ),
      _StatCard(icon: Icons.event_available_rounded, label: "Lectures Held", value: "$conductedCount"),
      _StatCard(
        icon: Icons.trending_up_rounded,
        label: "Overall Attendance",
        value: "${overallPercent.round()}%",
        highlight: true,
      ),
    ];

    final perRow = width >= 900 ? 5 : (width >= 700 ? 3 : 2);

    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += perRow) {
      final rowItems = cards.skip(i).take(perRow).toList();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int j = 0; j < perRow; j++) ...[
                  if (j > 0) const SizedBox(width: 10),
                  Expanded(child: j < rowItems.length ? rowItems[j] : const SizedBox()),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

// ---------------------------------------------------------------------------
// Small model for a chart row (semester or session)
// ---------------------------------------------------------------------------

class _AnalyticsRow {
  final String id;
  final String label;
  final String subtitle;
  final double percent;
  _AnalyticsRow({required this.id, required this.label, required this.subtitle, required this.percent});
}

// ---------------------------------------------------------------------------
// Semester / Session toggle
// ---------------------------------------------------------------------------

class _ViewToggle extends StatelessWidget {
  final bool semesterView;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.semesterView, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    Widget pill(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill("Semester", semesterView, () => onChanged(true)),
          pill("Session", !semesterView, () => onChanged(false)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grouped analytics bar chart with tap tooltips + legend
// ---------------------------------------------------------------------------

class _GroupedAnalyticsChart extends StatelessWidget {
  final List<_AnalyticsRow> rows;
  final List<Color> palette;
  const _GroupedAnalyticsChart({required this.rows, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 16, 10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: 100,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Colors.grey, width: 1),
                    left: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final row = rows[group.x.toInt()];
                      return BarTooltipItem(
                        "${row.label}\n${rod.toY.round()}%",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= rows.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(rows[i].label, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < rows.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: rows[i].percent,
                          color: palette[i % palette.length],
                          width: 22,
                          borderRadius: BorderRadius.circular(6),
                        )
                      ],
                    )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          for (int i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: palette[i % palette.length], shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rows[i].subtitle.isEmpty ? rows[i].label : "${rows[i].label} • ${rows[i].subtitle}",
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text("${rows[i].percent.round()}%",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Interactive, expandable department card — real present/late/absent
// counts and a real per-department 7-day trend, both computed straight
// from live lecture data (no placeholders).
// ---------------------------------------------------------------------------

class _DepartmentDetailCard extends StatelessWidget {
  final String name;
  final int totalStudents;
  final int percent;
  final bool expanded;
  final VoidCallback onTap;
  final Map<String, int> breakdown; // present, late, absent, total
  final List<double> trend; // 7 values
  final List<String> weekdayLabels;

  const _DepartmentDetailCard({
    super.key,
    required this.name,
    required this.totalStudents,
    required this.percent,
    required this.expanded,
    required this.onTap,
    required this.breakdown,
    required this.trend,
    required this.weekdayLabels,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: _cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: primary.withAlpha(30),
                      child: Icon(Icons.apartment_rounded, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text("$totalStudents Students",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Badge(
                      label: Text("$percent%"),
                      backgroundColor: primary,
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: expanded ? 0.5 : 0,
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(3),
                  minHeight: 7,
                  value: percent / 100,
                  color: primary,
                  backgroundColor: primary.withAlpha(25),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: expanded ? _buildExpanded(context) : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final present = breakdown['present'] ?? 0;
    final late = breakdown['late'] ?? 0;
    final absent = breakdown['absent'] ?? 0;
    final total = breakdown['total'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total == 0)
            Text("No attendance recorded yet", style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
          else ...[
            Row(
              children: [
                _MetricChip(label: "Present", value: present, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                _MetricChip(label: "Late", value: late, color: Colors.brown),
                const SizedBox(width: 8),
                _MetricChip(label: "Absent", value: absent, color: Colors.red),
              ],
            ),
            const SizedBox(height: 6),
            // stacked proportion bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (present > 0)
                      Expanded(
                        flex: present,
                        child: Container(color: Theme.of(context).primaryColor),
                      ),
                    if (late > 0)
                      Expanded(flex: late, child: Container(color: Colors.brown)),
                    if (absent > 0)
                      Expanded(flex: absent, child: Container(color: Colors.red)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text("Last 7 days", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SizedBox(
            height: 70,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= weekdayLabels.length) return const SizedBox();
                        return Text(weekdayLabels[i], style: const TextStyle(fontSize: 9));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withOpacity(0.12)),
                    spots: [for (int i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i])],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MetricChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text("$value", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared visual helpers
// ---------------------------------------------------------------------------

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.grey.shade300, width: 0.5),
  boxShadow: [
    BoxShadow(color: Colors.grey.shade200, blurRadius: 3, offset: const Offset(0, 1)),
  ],
);

class _CardEmpty extends StatelessWidget {
  final String label;
  const _CardEmpty({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: _cardDecoration(),
      child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: highlight
          ? BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
      )
          : _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: highlight ? Colors.white.withOpacity(0.2) : primary.withAlpha(30),
            child: Icon(icon, size: 15, color: highlight ? Colors.white : primary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: highlight ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: highlight ? Colors.white.withOpacity(0.85) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live attendance aggregator.
//
// Extended from the original: each lecture entry now also carries
// session_id/semester_id (already present on the indexDoc pointer, just
// wasn't being kept before), and the aggregator lazily fetches the real
// session `name` and semester `semester_no` the first time each id is
// seen -- one-time reads, cached, never re-fetched. Everything else stays
// realtime via the existing per-lecture snapshot listeners.
// ---------------------------------------------------------------------------

class _DeptAttendance {
  int presentSum = 0;
  int totalSum = 0;
  double get percentage => totalSum == 0 ? 0 : (presentSum / totalSum) * 100;
}

class _AttendanceAggregator {
  final DbService db;
  final String insAdminId;
  final String instituteId;

  _AttendanceAggregator({
    required this.db,
    required this.insAdminId,
    required this.instituteId,
  });

  StreamSubscription? _indexSub;
  final Map<String, StreamSubscription<DocumentSnapshot>> _lectureSubs = {};
  final Map<String, Map<String, dynamic>> _lectureData = {};

  // name caches for session/semester grouping
  final Map<String, String> _sessionNames = {};
  final Map<String, int> _semesterNos = {};
  final Map<String, String> _semesterSessionId = {};
  final Set<String> _pendingFetch = {};

  final _controller = StreamController<void>.broadcast();
  Stream<void> get updates => _controller.stream;

  bool hasLoadedOnce = false;

  void start() {
    _indexSub = db.indexDoc
        .where("institute_id", isEqualTo: instituteId)
        .where("type", isEqualTo: "lecture")
        .snapshots()
        .listen(_onIndexSnapshot);
  }

  void _onIndexSnapshot(QuerySnapshot snap) {
    final currentIds = snap.docs.map((d) => d.id).toSet();

    final toRemove = _lectureSubs.keys.where((id) => !currentIds.contains(id)).toList();
    for (final id in toRemove) {
      _lectureSubs.remove(id)?.cancel();
      _lectureData.remove(id);
    }

    for (final doc in snap.docs) {
      if (_lectureSubs.containsKey(doc.id)) continue;
      final idx = doc.data() as Map<String, dynamic>;

      final deptId = idx['department_id']?.toString();
      final sessionId = idx['session_id']?.toString();
      final semesterId = idx['semester_id']?.toString();

      if (deptId != null && sessionId != null) {
        _fetchSessionName(deptId, sessionId);
      }
      if (deptId != null && sessionId != null && semesterId != null) {
        _fetchSemesterNo(deptId, sessionId, semesterId);
      }

      final ref = db.dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(idx['department_id'])
          .collection("sessions").doc(idx['session_id'])
          .collection("semesters").doc(idx['semester_id'])
          .collection("courses").doc(idx['course_id'])
          .collection("lectures").doc(doc.id);

      _lectureSubs[doc.id] = ref.snapshots().listen((lecSnap) {
        if (!lecSnap.exists) {
          _lectureData.remove(doc.id);
        } else {
          final ldata = lecSnap.data() as Map<String, dynamic>;
          _lectureData[doc.id] = {
            "department_id": idx['department_id'],
            "session_id": idx['session_id'],
            "semester_id": idx['semester_id'],
            "dated": ldata['dated'],
            "status": ldata['status'],
            "attendance": ldata['attendance'],
          };
        }
        _controller.add(null);
      });
    }

    hasLoadedOnce = true;
    _controller.add(null);
  }

  Future<void> _fetchSessionName(String deptId, String sessionId) async {
    final cacheKey = "s_$sessionId";
    if (_sessionNames.containsKey(sessionId) || _pendingFetch.contains(cacheKey)) return;
    _pendingFetch.add(cacheKey);
    try {
      final doc = await db.dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(deptId)
          .collection("sessions").doc(sessionId)
          .get();
      if (doc.exists) {
        _sessionNames[sessionId] = (doc.data() as Map)['name']?.toString() ?? "Session";
        _controller.add(null);
      }
    } catch (_) {
      // leave uncached — falls back to a short id in the UI
    } finally {
      _pendingFetch.remove(cacheKey);
    }
  }

  Future<void> _fetchSemesterNo(String deptId, String sessionId, String semesterId) async {
    final cacheKey = "m_$semesterId";
    if (_semesterNos.containsKey(semesterId) || _pendingFetch.contains(cacheKey)) return;
    _pendingFetch.add(cacheKey);
    try {
      final doc = await db.dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(deptId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final raw = data['semester_no'];
        _semesterNos[semesterId] = raw is int ? raw : int.tryParse('$raw') ?? 0;
        _semesterSessionId[semesterId] = sessionId;
        _controller.add(null);
      }
    } catch (_) {
    } finally {
      _pendingFetch.remove(cacheKey);
    }
  }

  String sessionName(String sessionId) => _sessionNames[sessionId] ?? "Session";
  String semesterShortLabel(String semesterId) {
    final no = _semesterNos[semesterId];
    return no == null ? "Sem" : "Sem $no";
  }
  String sessionNameForSemester(String semesterId) {
    final sid = _semesterSessionId[semesterId];
    return sid == null ? "" : sessionName(sid);
  }
  int semesterSortKey(String semesterId) => _semesterNos[semesterId] ?? 0;

  static bool _isPresentLike(dynamic entry) {
    final s = (entry is Map ? entry['status'] : null)?.toString();
    return s == 'present' || s == 'late';
  }

  Map<String, _DeptAttendance> computeDepartmentStats() {
    final Map<String, _DeptAttendance> stats = {};
    for (final l in _lectureData.values) {
      final status = (l['status'] ?? '').toString();
      if (status == 'upcoming') continue;
      final deptId = l['department_id']?.toString();
      if (deptId == null) continue;

      final attendance = (l['attendance'] as List?) ?? [];
      final present = attendance.where(_isPresentLike).length;

      final stat = stats.putIfAbsent(deptId, () => _DeptAttendance());
      stat.presentSum += present;
      stat.totalSum += attendance.length;
    }
    return stats;
  }

  Map<String, _DeptAttendance> computeSessionStats() {
    final Map<String, _DeptAttendance> stats = {};
    for (final l in _lectureData.values) {
      final status = (l['status'] ?? '').toString();
      if (status == 'upcoming') continue;
      final sessionId = l['session_id']?.toString();
      if (sessionId == null) continue;

      final attendance = (l['attendance'] as List?) ?? [];
      final present = attendance.where(_isPresentLike).length;

      final stat = stats.putIfAbsent(sessionId, () => _DeptAttendance());
      stat.presentSum += present;
      stat.totalSum += attendance.length;
    }
    return stats;
  }

  Map<String, _DeptAttendance> computeSemesterStats() {
    final Map<String, _DeptAttendance> stats = {};
    for (final l in _lectureData.values) {
      final status = (l['status'] ?? '').toString();
      if (status == 'upcoming') continue;
      final semesterId = l['semester_id']?.toString();
      if (semesterId == null) continue;

      final attendance = (l['attendance'] as List?) ?? [];
      final present = attendance.where(_isPresentLike).length;

      final stat = stats.putIfAbsent(semesterId, () => _DeptAttendance());
      stat.presentSum += present;
      stat.totalSum += attendance.length;
    }
    return stats;
  }

  /// Real present/late/absent counts for one department — used by the
  /// expandable department card, not estimated from percentages.
  Map<String, int> computeDepartmentBreakdown(String deptId) {
    int present = 0, late = 0, absent = 0;
    for (final l in _lectureData.values) {
      if (l['department_id']?.toString() != deptId) continue;
      final status = (l['status'] ?? '').toString();
      if (status == 'upcoming') continue;
      final attendance = (l['attendance'] as List?) ?? [];
      for (final a in attendance) {
        final s = (a is Map ? a['status'] : null)?.toString();
        if (s == 'present') {
          present++;
        } else if (s == 'late') {
          late++;
        } else {
          absent++;
        }
      }
    }
    return {'present': present, 'late': late, 'absent': absent, 'total': present + late + absent};
  }

  List<double> computeDeptWeeklyTrend(String deptId) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    final Map<String, List<int>> perDay = {for (final d in days) _dayKey(d): [0, 0]};

    for (final l in _lectureData.values) {
      if (l['department_id']?.toString() != deptId) continue;
      final status = (l['status'] ?? '').toString();
      if (status == 'upcoming') continue;

      final tsRaw = l['dated'];
      if (tsRaw is! Timestamp) continue;
      final key = _dayKey(tsRaw.toDate());
      if (!perDay.containsKey(key)) continue;

      final attendance = (l['attendance'] as List?) ?? [];
      final present = attendance.where(_isPresentLike).length;
      perDay[key]![0] += present;
      perDay[key]![1] += attendance.length;
    }

    return days.map((d) {
      final vals = perDay[_dayKey(d)]!;
      return vals[1] == 0 ? 0.0 : (vals[0] / vals[1]) * 100;
    }).toList();
  }

  List<double> computeWeeklyPercentages() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    final Map<String, List<int>> perDay = {for (final d in days) _dayKey(d): [0, 0]};

    for (final l in _lectureData.values) {
      final status = (l['status'] ?? '').toString();
      if (status == 'upcoming') continue;

      final tsRaw = l['dated'];
      if (tsRaw is! Timestamp) continue;
      final key = _dayKey(tsRaw.toDate());
      if (!perDay.containsKey(key)) continue;

      final attendance = (l['attendance'] as List?) ?? [];
      final present = attendance.where(_isPresentLike).length;
      perDay[key]![0] += present;
      perDay[key]![1] += attendance.length;
    }

    return days.map((d) {
      final vals = perDay[_dayKey(d)]!;
      return vals[1] == 0 ? 0.0 : (vals[0] / vals[1]) * 100;
    }).toList();
  }

  double computeOverallPercentage() {
    int present = 0, total = 0;
    for (final l in _lectureData.values) {
      final status = (l['status'] ?? '').toString();
      if (status == 'upcoming') continue;
      final attendance = (l['attendance'] as List?) ?? [];
      present += attendance.where(_isPresentLike).length;
      total += attendance.length;
    }
    return total == 0 ? 0 : (present / total) * 100;
  }

  int computeConductedLectureCount() {
    return _lectureData.values.where((l) => (l['status'] ?? '').toString() != 'upcoming').length;
  }

  /// Present/total across every lecture dated today (regardless of
  /// department), for the live "Today's Attendance" stat card.
  Map<String, int> computeTodayStats() {
    final now = DateTime.now();
    int present = 0, total = 0;
    for (final l in _lectureData.values) {
      final tsRaw = l['dated'];
      if (tsRaw is! Timestamp) continue;
      final d = tsRaw.toDate();
      if (!(d.year == now.year && d.month == now.month && d.day == now.day)) continue;
      final status = (l['status'] ?? '').toString();
      if (status == 'upcoming') continue;
      final attendance = (l['attendance'] as List?) ?? [];
      present += attendance.where(_isPresentLike).length;
      total += attendance.length;
    }
    return {'present': present, 'total': total};
  }

  String _dayKey(DateTime d) => "${d.year}-${d.month}-${d.day}";

  void dispose() {
    _indexSub?.cancel();
    for (final s in _lectureSubs.values) {
      s.cancel();
    }//bar
    _controller.close();
  }
}