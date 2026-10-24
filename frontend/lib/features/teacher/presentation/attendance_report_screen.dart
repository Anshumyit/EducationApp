import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/teacher_provider.dart';
import 'mark_attendance_screen.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  final String? studentId;
  final String? studentName;

  const AttendanceReportScreen({super.key, this.studentId, this.studentName});

  @override
  ConsumerState<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends ConsumerState<AttendanceReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Single student mode state
  bool _isLoadingStudent = true;
  Map<String, dynamic>? _studentReportData;

  // Class mode state
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingDateLog = false;
  Map<String, dynamic>? _dateAttendanceData;
  List<dynamic> _recentLogs = [];
  bool _isLoadingRecentLogs = false;

  // Class monthly report state
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoadingMonthlyReport = false;
  Map<String, dynamic>? _classMonthlyReportData;
  String _monthlyFilter = 'ALL'; // ALL, CRITICAL, LATE, HIGH
  String _searchQuery = '';

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.studentId != null) {
        _fetchStudentReport();
      } else {
        _loadDailyAttendanceLog(_selectedDate);
        _loadRecentAttendanceLogs();
        _loadClassMonthlyReport();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // Single Student Report
  // -------------------------------------------------------------
  Future<void> _fetchStudentReport() async {
    setState(() => _isLoadingStudent = true);
    try {
      final res = await DioClient.instance.get(
        '${ApiConstants.studentAttendanceReport}/${widget.studentId}/report',
        queryParameters: {
          'month': _selectedMonth.toString(),
          'year': _selectedYear.toString(),
        },
      );
      setState(() {
        _studentReportData = res.data['data'];
        _isLoadingStudent = false;
      });
    } catch (_) {
      setState(() => _isLoadingStudent = false);
    }
  }

  // -------------------------------------------------------------
  // Class Daily Attendance Log
  // -------------------------------------------------------------
  Future<void> _loadDailyAttendanceLog(DateTime date) async {
    final teacherState = ref.read(teacherProvider);
    final classId = teacherState.classInfo?['classroom']?['_id'];
    if (classId == null) return;

    setState(() => _isLoadingDateLog = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final data = await ref.read(teacherProvider.notifier).fetchAttendanceForDate(
          classId: classId,
          date: dateStr,
        );

    setState(() {
      _dateAttendanceData = data;
      _isLoadingDateLog = false;
    });
  }

  Future<void> _loadRecentAttendanceLogs() async {
    final teacherState = ref.read(teacherProvider);
    final classId = teacherState.classInfo?['classroom']?['_id'];
    if (classId == null) return;

    setState(() => _isLoadingRecentLogs = true);
    final logs = await ref.read(teacherProvider.notifier).fetchClassAttendanceLogs(
          classId: classId,
        );

    setState(() {
      _recentLogs = logs;
      _isLoadingRecentLogs = false;
    });
  }

  // -------------------------------------------------------------
  // Class Monthly Report
  // -------------------------------------------------------------
  Future<void> _loadClassMonthlyReport() async {
    final teacherState = ref.read(teacherProvider);
    final classId = teacherState.classInfo?['classroom']?['_id'];
    if (classId == null) return;

    setState(() => _isLoadingMonthlyReport = true);
    final report = await ref.read(teacherProvider.notifier).fetchClassMonthlyReport(
          classId: classId,
          month: _selectedMonth.toString(),
          year: _selectedYear.toString(),
        );

    setState(() {
      _classMonthlyReportData = report;
      _isLoadingMonthlyReport = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadDailyAttendanceLog(picked);
    }
  }

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // If studentId is passed, render single student monthly report
    if (widget.studentId != null) {
      return _buildSingleStudentScreen();
    }

    // Otherwise, render full Class Attendance Hub (Daily Log + Monthly Report)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance Logs & Reports'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 20), text: 'Daily Log'),
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 20), text: 'Monthly Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyAttendanceLogTab(),
          _buildClassMonthlyReportTab(),
        ],
      ),
    );
  }

  // =============================================================
  // TAB 1: DAILY ATTENDANCE LOG
  // =============================================================
  Widget _buildDailyAttendanceLogTab() {
    final dateDisplay = DateFormat('EEEE, MMM d, yyyy').format(_selectedDate);
    final isMarked = _dateAttendanceData != null &&
        (_dateAttendanceData!['isMarked'] == true ||
            (_dateAttendanceData!['records'] as List?)?.isNotEmpty == true ||
            _dateAttendanceData!['attendance'] != null);

    final summary = _dateAttendanceData?['summary'] as Map<String, dynamic>?;
    final totalStudents = summary?['totalStudents'] ?? ref.read(teacherProvider).students.length;
    final presentCount = summary?['presentCount'] ?? 0;
    final absentCount = summary?['absentCount'] ?? 0;
    final lateCount = summary?['lateCount'] ?? 0;
    final absentStudents = (summary?['absentStudents'] as List<dynamic>?) ?? [];
    final lateStudents = (summary?['lateStudents'] as List<dynamic>?) ?? [];
    final presentStudents = (summary?['presentStudents'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        await _loadDailyAttendanceLog(_selectedDate);
        await _loadRecentAttendanceLogs();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Selector Bar
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.event_available_rounded, color: AppColors.primaryLight, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateDisplay,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              isMarked ? 'Attendance Recorded' : 'Not Yet Recorded',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isMarked ? AppColors.emerald : AppColors.amber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primaryLight),
                      label: Text('Change', style: GoogleFonts.outfit(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoadingDateLog)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!isMarked)
              // Empty State for Unrecorded Date
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_busy_rounded, color: AppColors.amber, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No Attendance Log for $dateDisplay',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Attendance has not been registered yet for this date. Click below to mark now.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MarkAttendanceScreen(initialDate: _selectedDate)),
                        ).then((_) {
                          _loadDailyAttendanceLog(_selectedDate);
                          _loadRecentAttendanceLogs();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                      label: Text(
                        'Mark Attendance for this Date',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Summary KPI Grid for Marked Date
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Students',
                      value: '$totalStudents',
                      icon: Icons.groups_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Present',
                      value: '$presentCount',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Absent',
                      value: '$absentCount',
                      icon: Icons.cancel_rounded,
                      color: AppColors.rose,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Late Arrivals',
                      value: '$lateCount',
                      icon: Icons.schedule_rounded,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action button to modify attendance
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MarkAttendanceScreen(initialDate: _selectedDate)),
                  ).then((_) {
                    _loadDailyAttendanceLog(_selectedDate);
                    _loadRecentAttendanceLogs();
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryLight),
                label: Text(
                  'Edit / Update Attendance for this Date',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                ),
              ),

              const SizedBox(height: 24),

              // 🔴 ABSENT STUDENTS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: AppColors.rose, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Absent Students (${absentStudents.length})',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (absentStudents.isEmpty)
                    Text('All present! 🎉', style: GoogleFonts.inter(fontSize: 12, color: AppColors.emerald)),
                ],
              ),
              const SizedBox(height: 10),

              if (absentStudents.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: Text(
                      'No students were absent on this day! 🌟',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.emerald, fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: absentStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final s = absentStudents[idx];
                    return GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.rose.withOpacity(0.15),
                            child: Text(
                              '${s['rollNumber'] ?? idx + 1}',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.rose),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['name'] ?? '',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                Text(
                                  'Status: Absent • Not in class',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.rose),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.rose.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'ABSENT',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.rose),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // 🟡 LATE STUDENTS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Late Students (${lateStudents.length})',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (lateStudents.isEmpty)
                    Text('No latecomers ⏱️', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),

              if (lateStudents.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: Text(
                      'No students arrived late on this day. 👍',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lateStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final s = lateStudents[idx];
                    return GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.amber.withOpacity(0.15),
                            child: Text(
                              '${s['rollNumber'] ?? idx + 1}',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.amber),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['name'] ?? '',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                Text(
                                  'Status: Late Arrival',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.amber),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'LATE',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.amber),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // 🟢 PRESENT STUDENTS SECTION (Collapsible)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    leading: const Icon(Icons.check_circle_rounded, color: AppColors.emerald),
                    title: Text(
                      'Present Students (${presentStudents.length})',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    subtitle: Text('Tap to expand list', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: presentStudents.map((s) {
                            return Chip(
                              backgroundColor: AppColors.surfaceLight,
                              avatar: CircleAvatar(
                                backgroundColor: AppColors.emerald.withOpacity(0.2),
                                child: Text(
                                  '#${s['rollNumber'] ?? ''}',
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald),
                                ),
                              ),
                              label: Text(
                                s['name'] ?? '',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                              ),
                              side: const BorderSide(color: AppColors.border),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // 📜 RECENT ATTENDANCE TIMELINE / HISTORY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Daily Attendance Logs',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Last 30 Days',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingRecentLogs)
              const Center(child: CircularProgressIndicator())
            else if (_recentLogs.isEmpty)
              const EmptyState(
                icon: Icons.history_rounded,
                title: 'No Past Records',
                description: 'No historical attendance records found for this class.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentLogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final log = _recentLogs[idx];
                  final logDateStr = log['date'] ?? '';
                  final logP = log['presentCount'] ?? 0;
                  final logA = log['absentCount'] ?? 0;
                  final logL = log['lateCount'] ?? 0;
                  final logAbsentList = (log['absentStudents'] as List<dynamic>?) ?? [];
                  final logLateList = (log['lateStudents'] as List<dynamic>?) ?? [];

                  DateTime? parsedDate;
                  try {
                    parsedDate = DateTime.parse(logDateStr);
                  } catch (_) {}
                  final formattedDate = parsedDate != null
                      ? DateFormat('EEE, MMM d, yyyy').format(parsedDate)
                      : logDateStr;

                  final isSelected = parsedDate != null &&
                      DateFormat('yyyy-MM-dd').format(parsedDate) ==
                          DateFormat('yyyy-MM-dd').format(_selectedDate);

                  return InkWell(
                    onTap: () {
                      if (parsedDate != null) {
                        setState(() => _selectedDate = parsedDate!);
                        _loadDailyAttendanceLog(parsedDate);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderColor: isSelected ? AppColors.primary : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_note_rounded,
                                    size: 18,
                                    color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _buildMiniBadge('P: $logP', AppColors.emerald),
                                  const SizedBox(width: 4),
                                  _buildMiniBadge('A: $logA', AppColors.rose),
                                  const SizedBox(width: 4),
                                  _buildMiniBadge('L: $logL', AppColors.amber),
                                ],
                              ),
                            ],
                          ),
                          if (logAbsentList.isNotEmpty || logLateList.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ...logAbsentList.map((s) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.rose.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '❌ ${s['name']}',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.rose, fontWeight: FontWeight.w600),
                                      ),
                                    )),
                                ...logLateList.map((s) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.amber.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '⏱️ ${s['name']}',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.amber, fontWeight: FontWeight.w600),
                                      ),
                                    )),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // TAB 2: CLASS MONTHLY REPORT
  // =============================================================
  Widget _buildClassMonthlyReportTab() {
    final totalWorkingDays = _classMonthlyReportData?['totalWorkingDays'] ?? 0;
    final totalStudents = _classMonthlyReportData?['totalStudents'] ?? 0;
    final classAverage = _classMonthlyReportData?['classAverage'] ?? 0.0;
    final studentReports = (_classMonthlyReportData?['studentReports'] as List<dynamic>?) ?? [];
    final dailyBreakdown = (_classMonthlyReportData?['dailyBreakdown'] as List<dynamic>?) ?? [];

    final filteredReports = studentReports.where((r) {
      final name = (r['name'] ?? '').toString().toLowerCase();
      final roll = (r['rollNumber'] ?? '').toString();
      final q = _searchQuery.toLowerCase();
      if (_searchQuery.isNotEmpty && !name.contains(q) && !roll.contains(q)) {
        return false;
      }
      final pct = (r['percentage'] as num?)?.toDouble() ?? 100.0;
      final late = (r['late'] as num?)?.toInt() ?? 0;
      if (_monthlyFilter == 'CRITICAL') return pct < 75.0;
      if (_monthlyFilter == 'HIGH') return pct >= 90.0;
      if (_monthlyFilter == 'LATE') return late > 0;
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadClassMonthlyReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month & Year Selector Header
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedMonth,
                          dropdownColor: AppColors.surface,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryLight),
                          items: List.generate(12, (index) {
                            return DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text(
                                _monthNames[index],
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMonth = val);
                              _loadClassMonthlyReport();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          dropdownColor: AppColors.surface,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryLight),
                          items: [2025, 2026, 2027, 2028].map((y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text(
                                '$y',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedYear = val);
                              _loadClassMonthlyReport();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _loadClassMonthlyReport,
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
                    tooltip: 'Refresh Monthly Report',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoadingMonthlyReport)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // Summary KPI Cards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Working Days',
                      value: '$totalWorkingDays',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Class Average',
                      value: '$classAverage%',
                      icon: Icons.analytics_rounded,
                      color: classAverage >= 75 ? AppColors.emerald : AppColors.rose,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Enrolled Students',
                      value: '$totalStudents',
                      icon: Icons.groups_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Low Attendance',
                      value: '${studentReports.where((r) => ((r['percentage'] ?? 100) as num) < 75).length}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.rose,
                      subtitle: '< 75% Critical',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search student name or roll number...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Students (${studentReports.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('CRITICAL', 'Critical < 75%'),
                    const SizedBox(width: 8),
                    _buildFilterChip('LATE', 'Latecomers'),
                    const SizedBox(width: 8),
                    _buildFilterChip('HIGH', 'High > 90%'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Student List
              if (filteredReports.isEmpty)
                const EmptyState(
                  icon: Icons.person_off_rounded,
                  title: 'No Students Found',
                  description: 'No students matching the selected filter criteria.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredReports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final report = filteredReports[idx];
                    final pct = (report['percentage'] as num?)?.toDouble() ?? 100.0;
                    final present = report['present'] ?? 0;
                    final absent = report['absent'] ?? 0;
                    final late = report['late'] ?? 0;

                    Color statusColor = AppColors.emerald;
                    if (pct < 75) {
                      statusColor = AppColors.rose;
                    } else if (pct < 85) {
                      statusColor = AppColors.amber;
                    }

                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.surface,
                                child: Text(
                                  '#${report['rollNumber'] ?? idx + 1}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report['name'] ?? '',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Present: $present • Absent: $absent • Late: $late',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$pct%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (pct / 100).clamp(0.0, 1.0),
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Daily Breakdown for the Month
              if (dailyBreakdown.isNotEmpty) ...[
                Text(
                  'Daily Attendance Register (Month-at-a-Glance)',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dailyBreakdown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final day = dailyBreakdown[idx];
                    final date = day['date'] ?? '';
                    final p = day['presentCount'] ?? 0;
                    final a = day['absentCount'] ?? 0;
                    final l = day['lateCount'] ?? 0;
                    final absList = (day['absentStudents'] as List<dynamic>?) ?? [];
                    final lateList = (day['lateStudents'] as List<dynamic>?) ?? [];

                    return GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              date,
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                _buildMiniBadge('P: $p', AppColors.emerald),
                                const SizedBox(width: 4),
                                _buildMiniBadge('A: $a', AppColors.rose),
                                const SizedBox(width: 4),
                                _buildMiniBadge('L: $l', AppColors.amber),
                              ],
                            ),
                          ),
                          if (absList.isNotEmpty || lateList.isNotEmpty)
                            Expanded(
                              flex: 5,
                              child: Text(
                                [
                                  if (absList.isNotEmpty) 'Abs: ${absList.map((s) => s['name']).join(', ')}',
                                  if (lateList.isNotEmpty) 'Late: ${lateList.map((s) => s['name']).join(', ')}',
                                ].join(' | '),
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SINGLE STUDENT REPORT SCREEN (When studentId is provided)
  // =============================================================
  Widget _buildSingleStudentScreen() {
    final summary = _studentReportData?['summary'];
    final dailyHistory = _studentReportData?['dailyHistory'] as List<dynamic>? ?? [];
    final percentage = summary?['percentage'] ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.studentName != null ? '${widget.studentName} Attendance' : 'Student Monthly Attendance'),
      ),
      body: _isLoadingStudent
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reporting Period: ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$percentage% Attendance',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: percentage >= 75 ? AppColors.emerald : AppColors.rose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Present Days',
                          value: '${summary?['present'] ?? 0}',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Absent Days',
                          value: '${summary?['absent'] ?? 0}',
                          icon: Icons.cancel_rounded,
                          color: AppColors.rose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Late Days',
                          value: '${summary?['late'] ?? 0}',
                          icon: Icons.access_time_filled_rounded,
                          color: AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Total Days',
                          value: '${summary?['totalWorkingDays'] ?? 0}',
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Daily Attendance Log',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (dailyHistory.isEmpty)
                    const EmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'No Logs Found',
                      description: 'No daily attendance records have been registered for this month.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dailyHistory.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final log = dailyHistory[index];
                        final status = log['status'] ?? 'PRESENT';

                        return GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.event_note_rounded, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 10),
                                  Text(
                                    log['date'] ?? '',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              StatusBadge(status: status),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  // -------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------
  Widget _buildFilterChip(String key, String label) {
    final isSelected = _monthlyFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _monthlyFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
