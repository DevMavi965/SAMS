import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/services/db_service.dart';

import '../../models/course.dart';
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
  // Color(0xFF4C6FFF)
  static const List<Color> palette = [
    Color.fromARGB(255, 0, 153, 136),
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
                LTCPie(insAdmin: widget.insAdmin, institute: widget.institute),
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
                          chart: _EnrollmentTrendChart(
                            insAdmin: widget.insAdmin,
                            institute: widget.institute,
                            indexDocRef: indexDocRef,
                            palette: palette,
                          )
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
                  _EnrollmentTrendChart(
                    insAdmin: widget.insAdmin,
                    institute: widget.institute,
                    indexDocRef: indexDocRef,
                    palette: palette,
                  )
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
// Lab vs Theory course pie
// getLTC walks each `type == "course"` indexDoc entry, follows its
// department/session/semester path down to the actual course document
// (via the doc's own id, falling back to a `course_id` field if present),
// and tallies how many are "lab" vs "theory". This intentionally reads the
// real course doc rather than trusting a `type` field that may only exist
// on indexDoc for the coarser "course" record marker.
// ---------------------------------------------------------------------------

class LTCPie extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const LTCPie({super.key, required this.insAdmin, required this.institute});

  @override
  State<LTCPie> createState() => _LTCPieState();
}

class _LTCPieState extends State<LTCPie> {
  late Future<Map<String, int>> _ltcFuture;

  static const List<Color> _ltcPalette = [
    Color.fromARGB(255, 0, 153, 136), // theory
    Color(0xFFFF6B6B), // lab
  ];

  @override
  void initState() {
    super.initState();
    _ltcFuture = getLTC(context, widget.insAdmin.id!, widget.institute.id!);
  }

  Future<Map<String, int>> getLTC(
      BuildContext context, String insAdminId, String instituteId) async {
    final db = Provider.of<DbService>(context, listen: false);

    int lab = 0;
    int theory = 0;

    final xdocs = await db.indexDoc
        .where("ins_admin_id", isEqualTo: insAdminId)
        .where("institute_id", isEqualTo: instituteId)
        .where("type", isEqualTo: "course")
        .get();

    for (var docR in xdocs.docs) {
      final data = docR.data() as Map<String, dynamic>;
      final courseId = data['course_id']?.toString() ?? docR.id;

      final courseDoc = await db.dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(data['department_id'])
          .collection("sessions").doc(data['session_id'])
          .collection("semesters").doc(data['semester_id'])
          .collection("courses").doc(courseId)
          .get();

      if (!courseDoc.exists) continue;

      final courseData = courseDoc.data() as Map<String, dynamic>?;
      final type = (courseData?['type']?.toString() ?? '').toLowerCase();
      if (type == 'lab') {
        lab++;
      } else if (type == 'theory') {
        theory++;
      }
    }

    return {"lab": lab, "theory": theory};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _ltcFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _CardLoading();
        }
        if (snap.hasError) {
          return _CardEmpty(label: "Couldn't load courses: ${snap.error}");
        }
        final data = snap.data;
        if (data == null) return const _CardEmpty(label: "No courses yet");

        final theory = data['theory'] ?? 0;
        final lab = data['lab'] ?? 0;
        final total = theory + lab;
        if (total == 0) return const _CardEmpty(label: "No courses yet");

        final entries = [
          MapEntry('Theory', theory),
          MapEntry('Lab', lab),
        ].where((e) => e.value > 0).toList();

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
                              color: _ltcPalette[i % _ltcPalette.length],
                              title:
                              "${(entries[i].value / total * 100).round()}%",
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
                                color: _ltcPalette[i % _ltcPalette.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(entries[i].key,
                                  style: const TextStyle(fontSize: 12)),
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
  }
}

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

class _EnrollmentTrendChart extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final CollectionReference indexDocRef;
  final List<Color> palette;
  const _EnrollmentTrendChart({
    required this.insAdmin,
    required this.institute,
    required this.indexDocRef,
    required this.palette,
  });

  @override
  State<_EnrollmentTrendChart> createState() => _EnrollmentTrendChartState();
}

class _EnrollmentTrendChartState extends State<_EnrollmentTrendChart> {
  static const monthLabels = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  late Future<Map<String, int>> _trendFuture;

  @override
  void initState() {
    super.initState();
    _trendFuture = _getMonthlyEnrollment();
  }

  // step 1: pull id/department_id/session_id/semester_id for every student
  // via indexDoc (cheap, single collection query).
  // step 2: for each one, fetch the real student doc down the nested path
  // to read its created_at, since indexDoc itself doesn't carry it.
  Future<Map<String, int>> _getMonthlyEnrollment() async {
    final db = Provider.of<DbService>(context, listen: false);
    final insAdminId = widget.insAdmin.id!;
    final instituteId = widget.institute.id!;

    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final Map<String, int> monthCounts = {
      for (var m in months) "${m.year}-${m.month}": 0
    };

    final indexSnap = await widget.indexDocRef
        .where("institute_id", isEqualTo: instituteId)
        .where("role", isEqualTo: "student")
        .get();

    for (var idxDoc in indexSnap.docs) {
      final idx = idxDoc.data() as Map<String, dynamic>;
      final departmentId = idx['department_id']?.toString();
      final sessionId = idx['session_id']?.toString();
      final semesterId = idx['semester_id']?.toString();
      if (departmentId == null || sessionId == null || semesterId == null) continue;

      final studentDoc = await db.dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departmentId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("students").doc(idxDoc.id)
          .get();

      if (!studentDoc.exists) continue;
      final data = studentDoc.data() as Map<String, dynamic>?;
      final ts = data?['created_at'];
      if (ts is Timestamp) {
        final d = ts.toDate();
        final key = "${d.year}-${d.month}";
        if (monthCounts.containsKey(key)) {
          monthCounts[key] = monthCounts[key]! + 1;
        }
      }
    }

    return monthCounts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _trendFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _CardLoading();
        }
        if (snap.hasError) {
          return _CardEmpty(label: "Couldn't load enrollment: ${snap.error}");
        }

        final monthCounts = snap.data ?? {};
        final now = DateTime.now();
        final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));

        final spots = <FlSpot>[
          for (int i = 0; i < months.length; i++)
            FlSpot(i.toDouble(),
                (monthCounts["${months[i].year}-${months[i].month}"] ?? 0).toDouble())
        ];
        final total = spots.fold<double>(0, (p, e) => p + e.y);
        if (total == 0) return const _CardEmpty(label: "No students yet");

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
                  color: widget.palette[0],
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: const Color(0x334C6FFF)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}