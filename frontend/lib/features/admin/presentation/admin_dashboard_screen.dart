import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import 'admin_attendance_screen.dart';
import 'broadcast_screen.dart';
import 'class_management_screen.dart';
import 'exam_management_screen.dart';
import 'fees_management_screen.dart';
import 'school_settings_screen.dart';
import 'student_management_screen.dart';
import 'teacher_directory_screen.dart';
import 'user_approvals_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final adminState = ref.watch(adminProvider);
    final stats = adminState.stats;

    final pendingTotal = stats?['pendingApprovals']?['total'] ?? adminState.pendingApprovals.length;
    final totalTeachers = stats?['totalTeachers'] ?? adminState.teachers.length;
    final totalStudents = stats?['totalStudents'] ?? 0;
    final totalParents = stats?['totalParents'] ?? 0;
    final totalClasses = stats?['totalClasses'] ?? 0;
    final totalSections = stats?['totalSections'] ?? 0;

    final todayAtt = stats?['todayAttendance'];
    final attEnrolled = todayAtt?['totalEnrolled'] ?? totalStudents;
    final attPresent = todayAtt?['presentCount'] ?? 0;
    final attAbsent = todayAtt?['absentCount'] ?? 0;
    final attLate = todayAtt?['lateCount'] ?? 0;
    final attPercentage = todayAtt?['percentage'] ?? 0;

    final fees = stats?['fees'];
    final feesCollected = fees?['totalCollected'] ?? 0;
    final feesPending = fees?['totalPending'] ?? 0;

    final recentActivities = stats?['recentActivities'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'Admin Portal',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Principal & Institutional Administrator • Session 2026-27',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: () => ref.read(adminProvider.notifier).loadDashboard(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.rose),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pending Approvals Alert Banner
              if (pendingTotal > 0)
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserApprovalsScreen()),
                    );
                    if (context.mounted) {
                      ref.read(adminProvider.notifier).loadDashboard();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.amberGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$pendingTotal Pending Registrations',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Teachers and parents awaiting your review to access portal.',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),

              // Today's Attendance Pulse Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
                  );
                },
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.how_to_reg_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Today's Campus Attendance",
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (attPercentage >= 75 ? AppColors.emerald : AppColors.amber).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$attPercentage% Present',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: attPercentage >= 75 ? AppColors.emerald : AppColors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: attEnrolled > 0 ? (attPresent / attEnrolled) : 0,
                        backgroundColor: AppColors.surfaceVariant,
                        color: attPercentage >= 75 ? AppColors.emerald : AppColors.amber,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAttPill('Present', '$attPresent', AppColors.emerald),
                          _buildAttPill('Absent', '$attAbsent', AppColors.rose),
                          _buildAttPill('Late', '$attLate', AppColors.amber),
                          _buildAttPill('Total Enrolled', '$attEnrolled', AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Financial Overview Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeesManagementScreen()),
                  );
                },
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.emerald, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fee Collections & Dues',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Collected: ₹${(feesCollected as num).toLocaleString()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.emerald,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• Due: ₹${(feesPending as num).toLocaleString()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),

              // Core Institutional Analytics Grid
              Text(
                'Campus Demographics',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Students',
                      value: '$totalStudents',
                      icon: Icons.school_rounded,
                      color: AppColors.emerald,
                      subtitle: 'Active Enrollments',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Total Faculty',
                      value: '$totalTeachers',
                      icon: Icons.badge_rounded,
                      color: AppColors.primary,
                      subtitle: 'Teaching Staff',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TeacherDirectoryScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Guardians Network',
                      value: '$totalParents',
                      icon: Icons.family_restroom_rounded,
                      color: AppColors.accent,
                      subtitle: 'Active Parents',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Classes & Sections',
                      value: '$totalClasses Classes',
                      icon: Icons.meeting_room_rounded,
                      color: AppColors.amber,
                      subtitle: '$totalSections Total Sections',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClassManagementScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Complete Admin Features Grid
              Text(
                'Administration Command Hub',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    _buildAdminActionTile(
                      icon: Icons.groups_rounded,
                      color: AppColors.emerald,
                      title: 'Student Management',
                      subtitle: 'Admissions, records, TC, promotions & roll assignment',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildAdminActionTile(
                      icon: Icons.badge_rounded,
                      color: AppColors.primary,
                      title: 'Teacher & Staff Directory',
                      subtitle: 'Faculty profiles, subject tagging & salary slips',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TeacherDirectoryScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildAdminActionTile(
                      icon: Icons.class_rounded,
                      color: AppColors.accent,
                      title: 'Classes, Sections & Timetable',
                      subtitle: 'Nursery to Class 12, sections A/B/C, periods & class teachers',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClassManagementScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildAdminActionTile(
                      icon: Icons.payments_rounded,
                      color: AppColors.emerald,
                      title: 'Fees & Payments Hub',
                      subtitle: 'Tuition/transport invoices, collection reports & receipts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FeesManagementScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildAdminActionTile(
                      icon: Icons.co_present_rounded,
                      color: AppColors.amber,
                      title: 'Attendance Command Center',
                      subtitle: 'Daily roll call pulse & 1-tap absent parent notifications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildAdminActionTile(
                      icon: Icons.grade_rounded,
                      color: AppColors.rose,
                      title: 'Examination & Results',
                      subtitle: 'Weekly/monthly/annual terms, report cards & rankings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExamManagementScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildAdminActionTile(
                      icon: Icons.campaign_rounded,
                      color: AppColors.primary,
                      title: 'Institutional Broadcast Notices',
                      subtitle: 'Push notifications to All Users, Teachers or Parents',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BroadcastScreen()),
                        );
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildAdminActionTile(
                      icon: Icons.verified_user_rounded,
                      color: AppColors.amber,
                      title: 'User Approvals Hub',
                      subtitle: 'Review & approve new faculty and guardian registrations',
                      badgeCount: pendingTotal,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserApprovalsScreen()),
                        );
                        if (context.mounted) {
                          ref.read(adminProvider.notifier).loadDashboard();
                        }
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildAdminActionTile(
                      icon: Icons.settings_suggest_rounded,
                      color: AppColors.accent,
                      title: 'School Settings & Operations',
                      subtitle: 'Institution profile, bus fleet routes & library catalog',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SchoolSettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Activities Feed
              if (recentActivities.isNotEmpty) ...[
                Text(
                  'Recent Institutional Activity',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...recentActivities.take(4).map((act) {
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_rounded, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act['title'] ?? 'Institutional Alert',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                act['message'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildAdminActionTile({
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
          fontSize: 11,
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

