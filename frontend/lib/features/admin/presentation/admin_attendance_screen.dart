import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAttendance();
    });
  }

  void _fetchAttendance() {
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    ref.read(adminProvider.notifier).loadAttendanceOverview(date: dateStr);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchAttendance();
    }
  }

  void _triggerNotifyAbsentParents() {
    final dateStr = _selectedDate.toIso8601String().split('T')[0];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: AppColors.amber),
            const SizedBox(width: 8),
            Text(
              'Notify Absent Parents?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'This will immediately send real-time push notifications & SMS alerts to parents of all students marked ABSENT on $dateStr.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () async {
              Navigator.pop(ctx);
              final count = await ref.read(adminProvider.notifier).notifyAbsentParents(date: dateStr);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count != null && count > 0
                          ? 'Successfully dispatched absence alerts to $count parents!'
                          : 'No absent students with reachable guardians found.',
                    ),
                    backgroundColor: count != null && count > 0 ? AppColors.emerald : AppColors.amber,
                  ),
                );
              }
            },
            child: const Text('Send Alerts Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final overview = adminState.attendanceOverview;

    final totalEnrolled = overview?['totalEnrolled'] ?? 0;
    final presentCount = overview?['presentCount'] ?? 0;
    final absentCount = overview?['absentCount'] ?? 0;
    final lateCount = overview?['lateCount'] ?? 0;
    final percentage = overview?['attendancePercentage'] ?? 0;
    final classBreakdown = overview?['classBreakdown'] as List? ?? [];
    final absentStudents = overview?['absentStudents'] as List? ?? [];

    final dateLabel = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Attendance Command',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            onPressed: _pickDate,
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchAttendance,
          ),
        ],
      ),
      floatingActionButton: absentStudents.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.rose,
              icon: const Icon(Icons.campaign_rounded, color: Colors.white),
              label: Text(
                'Notify Absent Parents (${absentStudents.length})',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              onPressed: _triggerNotifyAbsentParents,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _fetchAttendance(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_note_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Attendance Date: $dateLabel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedDate = DateTime.now());
                        _fetchAttendance();
                      },
                      child: const Text('Today', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Institution Attendance Pulse Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 76,
                              height: 76,
                              child: CircularProgressIndicator(
                                value: totalEnrolled > 0 ? (presentCount / totalEnrolled) : 0,
                                strokeWidth: 8,
                                backgroundColor: AppColors.surfaceVariant,
                                color: percentage >= 75 ? AppColors.emerald : AppColors.amber,
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Campus Roll Call Pulse',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$presentCount of $totalEnrolled students present on campus today.',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAttendanceMetric('Enrolled', '$totalEnrolled', AppColors.primary),
                        _buildAttendanceMetric('Present', '$presentCount', AppColors.emerald),
                        _buildAttendanceMetric('Absent', '$absentCount', AppColors.rose),
                        _buildAttendanceMetric('Late', '$lateCount', AppColors.amber),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Class-by-Class Attendance Breakdown
              Text(
                'Class-Wise Roll Call Breakdown',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              if (classBreakdown.isEmpty)
                const EmptyState(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'No Class Records',
                  message: 'Classes have not completed roll call for this date yet.',
                )
              else
                ...classBreakdown.map((cb) {
                  final pct = cb['percentage'] ?? 0;
                  final clsTotal = cb['totalStudents'] ?? 0;
                  final clsPresent = cb['present'] ?? 0;
                  final clsAbsent = cb['absent'] ?? 0;

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cb['className'] ?? 'Class',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (pct >= 75 ? AppColors.emerald : AppColors.amber).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pct% Present',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: pct >= 75 ? AppColors.emerald : AppColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Teacher: ${cb['classTeacher']} • $clsPresent Present, $clsAbsent Absent ($clsTotal Enrolled)',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: clsTotal > 0 ? (clsPresent / clsTotal) : 0,
                          backgroundColor: AppColors.surfaceVariant,
                          color: pct >= 75 ? AppColors.emerald : AppColors.amber,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // Today's Absentee Roster
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Absent Students Roster (${absentStudents.length})',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  if (absentStudents.isNotEmpty)
                    Text(
                      'Ready to Alert',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.rose, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (absentStudents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.emerald),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Zero absences recorded for this date! Perfect attendance across all classes.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...absentStudents.map((abs) {
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.rose.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_off_rounded, color: AppColors.rose, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                abs['studentName'] ?? 'Student',
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Roll #${abs['rollNumber']} • ${abs['className']} • Adm: ${abs['admissionNumber']}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Guardian: ${abs['parentName']} (${abs['parentPhone'] ?? "N/A"})',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: 'ABSENT', color: AppColors.rose),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
