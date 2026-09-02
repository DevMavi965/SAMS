import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/services/db_service.dart';

/// Realtime institute-wide analytics.
///
/// Requires the `fl_chart` package:
///   flutter pub add fl_chart
///
/// DATA SOURCE
/// -----------
/// Students, faculty and courses are read from the flat `indexDoc`
/// collection (`SAMS/SAMS_DB/index`) instead of Firestore `collectionGroup`
/// queries. `indexDoc` already stores `institute_id`, `department_id` and a
/// `role`/`type` marker for every student, faculty and course record (see
/// db_service.dart), so a plain equality query on that single collection
/// gets us the same counts and breakdowns without:
///   - needing a `collectionGroup` composite index per collection (the
///     FAILED_PRECONDITION prompt the old version warned about), and
///   - fanning the query out across every session/semester subtree.
/// Multi-equality `.where()` queries (all `==`, no range/orderBy on a
/// different field) don't need a composite index in Firestore, so these
/// queries work out of the box.
///
/// NOTE: this assumes `role` is stored as the literal strings "student" and
/// "faculty" on indexDoc entries (see registerStudent/registerFac in
/// db_service.dart). If your Lecturer model actually writes something else
/// (e.g. "lecturer"), update `_facultyRole` below to match.
/// The enrollment trend also needs `created_at` and the course pie needs
/// `course_type` on indexDoc entries — see the patch notes for db_service.dart.
///
/// LAYOUT
/// ------
/// The whole screen is wrapped in a `LayoutBuilder`. Below ~800px (phones)
/// everything stacks in a single column, same as before. At ~800px and up
/// (tablets/desktop/web) related charts are placed side-by-side using
/// `Row` + `Expanded`, and the stat cards flow into as many per row as fit
/// using `Row` + `Expanded` instead of a fixed 3-column `GridView`.
class InsReports extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const InsReports({super.key, required this.insAdmin, required this.institute});

  @override
  State<InsReports> createState() => _InsReportsState();
}

class _InsReportsState extends State<InsReports> {
  static const String _facultyRole = "faculty"; // verify against Lecturer.role

  late final CollectionReference departmentsRef;
  late final CollectionReference adminsRef;
  late final CollectionReference leaveAppsRef;
  late final CollectionReference indexDocRef;

  static const List<Color> palette = [
    Color(0xFF4C6FFF),
    Color(0xFFFF6B6B),
    Color(0xFFFFB84C),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
    Color(0xFF38BDF8),
    Color(0xFFF472B6),
    Color(0xFF94A3B8),
  ];

  @override
  void initState() {
    super.initState();
    final db = Provider.of<DbService>(context, listen: false);
    final dbref = db.dbref;
    indexDocRef = db.indexDoc;
    final base = dbref
        .collection("ins_admins").doc(widget.insAdmin.id)
        .collection("institutes").doc(widget.institute.id);
    departmentsRef = base.collection("departments");
    adminsRef = base.collection("admins");
    leaveAppsRef = base.collection("leave_applications");
  }

  // Fast, single-collection lookups via indexDoc — see the class doc above.
  Stream<QuerySnapshot> get _studentsStream => indexDocRef
      .where("institute_id", isEqualTo: widget.institute.id)
      .where("role", isEqualTo: "student")
      .snapshots();

  Stream<QuerySnapshot> get _facultyStream => indexDocRef
      .where("institute_id", isEqualTo: widget.institute.id)
      .where("role", isEqualTo: _facultyRole)
      .snapshots();

  Stream<QuerySnapshot> get _coursesStream => indexDocRef
      .where("institute_id", isEqualTo: widget.institute.id)
      .where("type", isEqualTo: "course")
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Institute Analytics")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            return ListView(
              padding: const EdgeInsets.all(15),
              children: [
                Text(widget.institute.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text("Live overview of your institute",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 18),
                _buildStatGrid(constraints.maxWidth),
                const SizedBox(height: 24),

                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _sectionWithChart(
                          title: "Students by Department",
                          chart: _DistributionPie(
                            departmentsRef: departmentsRef,
                            itemsStream: _studentsStream,
                            palette: palette,
                            emptyLabel: "No students yet",
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _sectionWithChart(
                          title: "Faculty by Department",
                          chart: _DistributionPie(
                            departmentsRef: departmentsRef,
                            itemsStream: _facultyStream,
                            palette: palette,
                            emptyLabel: "No faculty yet",
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _sectionTitle("Students by Department"),
                  const SizedBox(height: 10),
                  _DistributionPie(
                    departmentsRef: departmentsRef,
                    itemsStream: _studentsStream,
                    palette: palette,
                    emptyLabel: "No students yet",
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle("Faculty by Department"),
                  const SizedBox(height: 10),
                  _DistributionPie(
                    departmentsRef: departmentsRef,
                    itemsStream: _facultyStream,
                    palette: palette,
                    emptyLabel: "No faculty yet",
                  ),
                ],

                const SizedBox(height: 24),
                _sectionTitle("Courses: Theory vs Lab"),
                const SizedBox(height: 10),
                _CourseTypePie(coursesStream: _coursesStream, palette: palette),
                const SizedBox(height: 24),

                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _sectionWithChart(
                          title: "Leave Applications",
                          chart: _LeaveStatusBarChart(leaveAppsRef: leaveAppsRef, palette: palette),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _sectionWithChart(
                          title: "Student Enrollment Trend",
                          chart: _EnrollmentTrendChart(studentsStream: _studentsStream, palette: palette),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _sectionTitle("Leave Applications"),
                  const SizedBox(height: 10),
                  _LeaveStatusBarChart(leaveAppsRef: leaveAppsRef, palette: palette),
                  const SizedBox(height: 24),
                  _sectionTitle("Student Enrollment Trend"),
                  const SizedBox(height: 10),
                  _EnrollmentTrendChart(studentsStream: _studentsStream, palette: palette),
                ],

                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
  }

  Widget _sectionWithChart({required String title, required Widget chart}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        const SizedBox(height: 10),
        chart,
      ],
    );
  }

  /// Stat cards laid out with Row + Expanded (rather than a fixed-column
  /// GridView) so the number of cards per row grows with the available
  /// width — 3 on a phone, more on a tablet/desktop/web window.
  Widget _buildStatGrid(double width) {
    final cards = <Widget>[
      _StatCard(
        icon: Icons.apartment_rounded,
        label: "Departments",
        stream: departmentsRef.snapshots().map((s) => s.docs.length),
      ),
      _StatCard(
        icon: Icons.school_rounded,
        label: "Students",
        stream: _studentsStream.map((s) => s.docs.length),
      ),
      _StatCard(
        icon: Icons.badge_rounded,
        label: "Faculty",
        stream: _facultyStream.map((s) => s.docs.length),
      ),
      _StatCard(
        icon: Icons.menu_book_rounded,
        label: "Courses",
        stream: _coursesStream.map((s) => s.docs.length),
      ),
      _StatCard(
        icon: Icons.admin_panel_settings_rounded,
        label: "Admins",
        stream: adminsRef.snapshots().map((s) => s.docs.length),
      ),
      _StatCard(
        icon: Icons.pending_actions_rounded,
        label: "Pending Leaves",
        stream: leaveAppsRef
            .where("status", isEqualTo: "pending")
            .snapshots()
            .map((s) => s.docs.length),
      ),
    ];

    final perRow = width >= 900
        ? 6
        : width >= 700
        ? 4
        : 3;

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
// Shared helpers
// ---------------------------------------------------------------------------

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.grey.shade300, width: 0.5),
  boxShadow: [
    BoxShadow(color: Colors.grey.shade200, blurRadius: 3, offset: const Offset(0, 1)),
  ],
);

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _CardLoading extends StatelessWidget {
  const _CardLoading();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      alignment: Alignment.center,
      decoration: _cardDecoration(),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

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

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Stream<int> stream;
  const _StatCard({required this.icon, required this.label, required this.stream});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
            child: Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: StreamBuilder<int>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return Text(
                  "${snap.data}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                );
              },
            ),
          ),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Department-wise distribution pie (used for students & faculty)
// Sourced from indexDoc: entries carry `department_id` for both students
// and faculty, so no join back to the students/faculty subcollections is
// needed.
// ---------------------------------------------------------------------------

class _DistributionPie extends StatelessWidget {
  final CollectionReference departmentsRef;
  final Stream<QuerySnapshot> itemsStream;
  final List<Color> palette;
  final String emptyLabel;
  const _DistributionPie({
    required this.departmentsRef,
    required this.itemsStream,
    required this.palette,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: departmentsRef.snapshots(),
      builder: (context, deptSnap) {
        if (!deptSnap.hasData) return const _CardLoading();
        final Map<String, String> deptNames = {
          for (var d in deptSnap.data!.docs)
            d.id: (d.data() as Map)['name']?.toString() ?? "Unnamed"
        };
        return StreamBuilder<QuerySnapshot>(
          stream: itemsStream,
          builder: (context, itemSnap) {
            if (!itemSnap.hasData) return const _CardLoading();
            final docs = itemSnap.data!.docs;
            if (docs.isEmpty) return _CardEmpty(label: emptyLabel);

            final Map<String, int> counts = {};
            for (var doc in docs) {
              final data = doc.data() as Map;
              final deptId = data['department_id']?.toString() ?? 'unknown';
              counts[deptId] = (counts[deptId] ?? 0) + 1;
            }
            final entries = counts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final total = docs.length;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: [
                              for (int i = 0; i < entries.length; i++)
                                PieChartSectionData(
                                  value: entries[i].value.toDouble(),
                                  color: palette[i % palette.length],
                                  title: "${(entries[i].value / total * 100).round()}%",
                                  radius: 40,
                                  titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < entries.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: palette[i % palette.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    deptNames[entries[i].key] ?? "Unknown",
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text("${entries[i].value}",
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Course type pie (theory / lab / whatever `course_type` values exist)
// Sourced from indexDoc's `course_type` field — see the db_service.dart
// patch notes: this is distinct from the `type` field used to mark the
// record itself as `"course"`.
// ---------------------------------------------------------------------------

class _CourseTypePie extends StatelessWidget {
  final Stream<QuerySnapshot> coursesStream;
  final List<Color> palette;
  const _CourseTypePie({required this.coursesStream, required this.palette});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: coursesStream,
      builder: (context, snap) {
        if (!snap.hasData) return const _CardLoading();
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const _CardEmpty(label: "No courses yet");

        final Map<String, int> counts = {};
        for (var doc in docs) {
          final data = doc.data() as Map;
          final type = (data['type']?.toString() ?? 'Unspecified');
          counts[type] = (counts[type] ?? 0) + 1;
        }
        final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final total = docs.length;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          for (int i = 0; i < entries.length; i++)
                            PieChartSectionData(
                              value: entries[i].value.toDouble(),
                              color: palette[i % palette.length],
                              title: "${(entries[i].value / total * 100).round()}%",
                              radius: 40,
                              titleStyle: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < entries.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                  color: palette[i % palette.length], shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(_cap(entries[i].key),
                                    style: const TextStyle(fontSize: 12))),
                            Text("${entries[i].value}",
                                style:
                                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Leave applications bar chart (pending / approved / rejected)
// ---------------------------------------------------------------------------

class _LeaveStatusBarChart extends StatelessWidget {
  final CollectionReference leaveAppsRef;
  final List<Color> palette;
  const _LeaveStatusBarChart({required this.leaveAppsRef, required this.palette});

  static const statuses = ["pending", "approved", "rejected"];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: leaveAppsRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const _CardLoading();
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const _CardEmpty(label: "No leave applications yet");

        final Map<String, int> counts = {for (var s in statuses) s: 0};
        for (var doc in docs) {
          final data = doc.data() as Map;
          final status = (data['status']?.toString() ?? 'pending').toLowerCase();
          counts[status] = (counts[status] ?? 0) + 1;
        }
        final maxY = counts.values.fold<int>(0, (p, e) => e > p ? e : p).toDouble();
        const colors = {
          "pending": Color(0xFFFFB84C),
          "approved": Color(0xFF34D399),
          "rejected": Color(0xFFFF6B6B),
        };

        return Container(
          height: 190,
          padding: const EdgeInsets.fromLTRB(10, 16, 16, 6),
          decoration: _cardDecoration(),
          child: BarChart(
            BarChartData(
              maxY: maxY == 0 ? 1 : maxY + 1,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= statuses.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_cap(statuses[i]), style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 0; i < statuses.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: counts[statuses[i]]!.toDouble(),
                        color: colors[statuses[i]],
                        width: 28,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Enrollment trend — students grouped by month of `created_at`, last 6 months
// Reads created_at from the indexDoc entry now (see registerStudent patch);
// students registered before that patch won't have it and simply won't
// contribute to this chart until they're re-saved.
// ---------------------------------------------------------------------------

class _EnrollmentTrendChart extends StatelessWidget {
  final Stream<QuerySnapshot> studentsStream;
  final List<Color> palette;
  const _EnrollmentTrendChart({required this.studentsStream, required this.palette});

  static const monthLabels = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: studentsStream,
      builder: (context, snap) {
        if (!snap.hasData) return const _CardLoading();
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const _CardEmpty(label: "No students yet");

        final now = DateTime.now();
        final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
        final Map<String, int> monthCounts = {
          for (var m in months) "${m.year}-${m.month}": 0
        };
        for (var doc in docs) {
          final data = doc.data() as Map;
          final ts = data['created_at'];
          if (ts is Timestamp) {
            final d = ts.toDate();
            final key = "${d.year}-${d.month}";
            if (monthCounts.containsKey(key)) {
              monthCounts[key] = monthCounts[key]! + 1;
            }
          }
        }
        final spots = <FlSpot>[
          for (int i = 0; i < months.length; i++)
            FlSpot(i.toDouble(), (monthCounts["${months[i].year}-${months[i].month}"] ?? 0).toDouble())
        ];
        final maxY = spots.map((s) => s.y).fold<double>(0, (p, e) => e > p ? e : p);

        return Container(
          height: 190,
          padding: const EdgeInsets.fromLTRB(6, 16, 16, 6),
          decoration: _cardDecoration(),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY == 0 ? 1 : maxY + 1,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= months.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(monthLabels[months[i].month - 1],
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: palette[0],
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: Color(0x334C6FFF)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}