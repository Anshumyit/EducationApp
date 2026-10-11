import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/parent_provider.dart';
import 'apply_leave_screen.dart';
import 'child_attendance_screen.dart';
import 'child_results_screen.dart';
import 'fee_management_screen.dart';
import 'holiday_calendar_screen.dart';
import 'homework_tracker_screen.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final parentState = ref.watch(parentProvider);
    final children = parentState.children;
    final child = parentState.currentChild;
    final childDashboard = parentState.childDashboard;

    final todayAttendance = childDashboard?['todayAttendance'] ?? 'NOT_YET_MARKED';
    final homeworkCount = parentState.homeworkList.length;
    final totalFeeDue = childDashboard?['totalFeeDue'] ?? 0;
    final latestResult = childDashboard?['latestResult'];

    final classroom = child?['classId'] is Map ? child['classId'] : null;
    final className = classroom != null ? '${classroom['name']} - ${classroom['section']}' : 'Class 10 - A';
    final classTeacherName = classroom?['classTeacher'] is Map ? classroom['classTeacher']['name'] : 'Rahul Sharma';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.name ?? 'Parent Portal', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Guardian & Family Portal', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.rose),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(parentProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Child Switcher Chips (if multiple children)
              if (children.length > 1) ...[
                Text(
                  'Select Child Profile',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(children.length, (idx) {
                    final c = children[idx];
                    final isSelected = parentState.selectedChildIndex == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ref.read(parentProvider.notifier).selectChild(idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(
                            c['name'] ?? 'Child',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // Child Overview Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                gradient: AppColors.cardGradient,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.accent.withOpacity(0.2),
                      child: Text(
                        child != null && child['name'] != null ? child['name'][0].toUpperCase() : 'C',
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child?['name'] ?? 'Student Profile',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Roll #${child?['rollNumber'] ?? 1} • $className',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Class Teacher: $classTeacherName',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Today's Live Attendance Alert
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChildAttendanceScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: todayAttendance == 'PRESENT'
                        ? AppColors.emerald.withOpacity(0.14)
                        : todayAttendance == 'ABSENT'
                            ? AppColors.rose.withOpacity(0.14)
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: todayAttendance == 'PRESENT'
                          ? AppColors.emerald.withOpacity(0.4)
                          : todayAttendance == 'ABSENT'
                              ? AppColors.rose.withOpacity(0.4)
                              : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        todayAttendance == 'PRESENT'
                            ? Icons.check_circle_rounded
                            : todayAttendance == 'ABSENT'
                                ? Icons.cancel_rounded
                                : Icons.schedule_rounded,
                        color: todayAttendance == 'PRESENT'
                            ? AppColors.emerald
                            : todayAttendance == 'ABSENT'
                                ? AppColors.rose
                                : AppColors.amber,
                        size: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todayAttendance == 'PRESENT'
                                  ? 'Marked Present Today'
                                  : todayAttendance == 'ABSENT'
                                      ? 'Marked Absent Today'
                                      : 'Roll Call Pending Today',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Instant notification triggered by class teacher',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // KPI Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Active Homework',
                      value: '$homeworkCount',
                      icon: Icons.menu_book_rounded,
                      color: AppColors.purple,
                      subtitle: 'Pending',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeworkTrackerScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      title: 'Recent Exam',
                      value: latestResult != null ? '${latestResult['percentage']}%' : '92.5%',
                      icon: Icons.grade_rounded,
                      color: AppColors.emerald,
                      subtitle: 'Grade A+',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChildResultsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Pending Fees',
                      value: '₹$totalFeeDue',
                      icon: Icons.payments_rounded,
                      color: AppColors.amber,
                      subtitle: 'Current Dues',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FeeManagementScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      title: 'Attendance Rate',
                      value: '95.2%',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.accent,
                      subtitle: 'October Month',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChildAttendanceScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'Parent Action Services',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Action tiles
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildServiceTile(
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.emerald,
                      title: 'Daily & Monthly Attendance Reports',
                      subtitle: 'Real-time roll call logs & monthly percentage tracker',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChildAttendanceScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildServiceTile(
                      icon: Icons.analytics_rounded,
                      color: AppColors.primaryLight,
                      title: 'Academic Results & Report Cards',
                      subtitle: 'Weekly tests, monthly tests, 6-Mo & 1-Yr annual marks',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChildResultsScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildServiceTile(
                      icon: Icons.assignment_rounded,
                      color: AppColors.purple,
                      title: 'Student Homework & Deadlines',
                      subtitle: 'Subject-wise assignments with submission due dates',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeworkTrackerScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildServiceTile(
                      icon: Icons.beach_access_rounded,
                      color: AppColors.amber,
                      title: 'Apply for Student Leave',
                      subtitle: 'Submit leave applications directly to the class teacher',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildServiceTile(
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.emerald,
                      title: 'Student Fee Management',
                      subtitle: 'Check balances, payment history & pay online installments',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FeeManagementScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildServiceTile(
                      icon: Icons.celebration_rounded,
                      color: AppColors.rose,
                      title: 'School Holiday Calendar',
                      subtitle: 'Upcoming festival holidays, vacation dates & school events',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HolidayCalendarScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
    );
  }
}
