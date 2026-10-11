import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/teacher_provider.dart';
import 'attendance_report_screen.dart';
import 'create_homework_screen.dart';
import 'leave_approval_screen.dart';
import 'mark_attendance_screen.dart';
import 'marks_entry_screen.dart';
import 'student_list_screen.dart';
import 'teacher_salary_screen.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teacherProvider.notifier).loadDashboard();
    });
  }

  void _showNoticeDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Instant Class Notice to Parents',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Send real-time alert to all parents of your assigned class',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: titleController,
              label: 'Notice Title',
              hint: 'e.g. Science Fair Project Submissions',
              prefixIcon: Icons.campaign_rounded,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: messageController,
              label: 'Notice Message',
              hint: 'Write announcement details...',
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Send Instant Notice',
              icon: Icons.send_rounded,
              onPressed: () async {
                final ok = await ref.read(teacherProvider.notifier).sendNotice(
                      title: titleController.text.trim(),
                      message: messageController.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.emerald,
                      content: Text('Notice sent to class parents! 📢'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final teacherState = ref.watch(teacherProvider);
    final classInfo = teacherState.classInfo;
    final students = teacherState.students;
    final pendingLeaves = teacherState.leaveRequests.where((l) => l['status'] == 'PENDING').length;

    final classroom = classInfo?['classroom'];
    final className = classroom != null ? '${classroom['name']} - ${classroom['section']}' : 'Class 10 - A';
    final roomNumber = classroom?['roomNumber'] ?? 'Room 204';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.name ?? 'Teacher Portal', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              user?.isClassTeacher == true ? 'Class Teacher ($className)' : 'Faculty Member',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
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
        onRefresh: () => ref.read(teacherProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Class Banner
              GlassCard(
                padding: const EdgeInsets.all(20),
                gradient: AppColors.cardGradient,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            className,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$roomNumber • Assigned Class Teacher',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.emerald, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // KPI Stats Grid
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Students',
                      value: '${students.length}',
                      icon: Icons.groups_rounded,
                      color: AppColors.primary,
                      subtitle: 'In My Class',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentListScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      title: 'Pending Leaves',
                      value: '$pendingLeaves',
                      icon: Icons.beach_access_rounded,
                      color: AppColors.amber,
                      subtitle: 'Parent Requests',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LeaveApprovalScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'Class Teacher Academic Hub',
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
                    _buildHubTile(
                      icon: Icons.how_to_reg_rounded,
                      color: AppColors.emerald,
                      title: 'Mark Daily Attendance',
                      subtitle: 'Record attendance & send instant parent alerts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildHubTile(
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.accent,
                      title: 'Monthly Attendance Reports',
                      subtitle: 'Student-by-student & class-wide attendance sheets',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildHubTile(
                      icon: Icons.fact_check_rounded,
                      color: AppColors.primaryLight,
                      title: 'Record Exam Marks & Results',
                      subtitle: 'Weekly tests, Monthly exams, 6-Mo & 1-Yr report cards',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MarksEntryScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildHubTile(
                      icon: Icons.menu_book_rounded,
                      color: AppColors.purple,
                      title: 'Assign Homework & Deadlines',
                      subtitle: 'Subject-wise assignments with automatic parent push',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateHomeworkScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildHubTile(
                      icon: Icons.person_search_rounded,
                      color: AppColors.accent,
                      title: 'Class Student Directory',
                      subtitle: 'View all student profiles, parent info & contacts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentListScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildHubTile(
                      icon: Icons.time_to_leave_rounded,
                      color: AppColors.amber,
                      title: 'Leave Applications Review',
                      subtitle: 'Approve or reject parent leave applications',
                      badgeCount: pendingLeaves,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LeaveApprovalScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildHubTile(
                      icon: Icons.campaign_rounded,
                      color: AppColors.rose,
                      title: 'Instant Class Parent Notice',
                      subtitle: 'Push immediate notice to all parents in your class',
                      onTap: _showNoticeDialog,
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildHubTile(
                      icon: Icons.payments_rounded,
                      color: AppColors.emerald,
                      title: 'My Salary Slips',
                      subtitle: 'View & download monthly disbursement receipts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TeacherSalaryScreen()),
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

  Widget _buildHubTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    int? badgeCount,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount != null && badgeCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
