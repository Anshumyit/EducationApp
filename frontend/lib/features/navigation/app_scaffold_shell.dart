import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../admin/presentation/admin_dashboard_screen.dart';
import '../admin/presentation/teacher_directory_screen.dart';
import '../admin/presentation/user_approvals_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../notifications/presentation/notifications_screen.dart';
import '../notifications/providers/notification_provider.dart';
import '../parent/presentation/child_attendance_screen.dart';
import '../parent/presentation/homework_tracker_screen.dart';
import '../parent/presentation/parent_dashboard_screen.dart';
import '../teacher/presentation/mark_attendance_screen.dart';
import '../teacher/presentation/student_list_screen.dart';
import '../teacher/presentation/teacher_dashboard_screen.dart';
import '../super_admin/presentation/super_admin_dashboard_screen.dart';
import '../super_admin/presentation/schools_management_screen.dart';
import '../super_admin/presentation/admin_accounts_screen.dart';
import '../super_admin/presentation/permission_matrix_screen.dart';
import '../super_admin/presentation/central_broadcast_screen.dart';

class AppScaffoldShell extends ConsumerStatefulWidget {
  const AppScaffoldShell({super.key});

  @override
  ConsumerState<AppScaffoldShell> createState() => _AppScaffoldShellState();
}

class _AppScaffoldShellState extends ConsumerState<AppScaffoldShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final unreadCount = ref.watch(notificationProvider).unreadCount;

    if (user == null) return const SizedBox();

    List<Widget> screens = [];
    List<NavigationDestination> items = [];

    if (user.isSuperAdmin) {
      screens = [
        const SuperAdminDashboardScreen(),
        const SchoolsManagementScreen(),
        const AdminAccountsScreen(),
        const PermissionMatrixScreen(),
        const CentralBroadcastScreen(),
      ];
      items = [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        const NavigationDestination(icon: Icon(Icons.domain_outlined), selectedIcon: Icon(Icons.domain_rounded), label: 'Schools'),
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings_rounded), label: 'Admins'),
        const NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune_rounded), label: 'Limits'),
        const NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: 'Broadcast'),
      ];
    } else if (user.isAdmin) {
      screens = [
        const AdminDashboardScreen(),
        const TeacherDirectoryScreen(),
        const UserApprovalsScreen(),
        const NotificationsScreen(),
      ];
      items = [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Teachers'),
        const NavigationDestination(icon: Icon(Icons.checklist_rtl_rounded), selectedIcon: Icon(Icons.checklist_rounded), label: 'Approvals'),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_rounded),
          ),
          label: 'Alerts',
        ),
      ];
    } else if (user.isTeacher) {
      screens = [
        const TeacherDashboardScreen(),
        const StudentListScreen(),
        const MarkAttendanceScreen(),
        const NotificationsScreen(),
      ];
      items = [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Students'),
        const NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), selectedIcon: Icon(Icons.how_to_reg_rounded), label: 'Roll Call'),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_rounded),
          ),
          label: 'Alerts',
        ),
      ];
    } else {
      // Parent
      screens = [
        const ParentDashboardScreen(),
        const ChildAttendanceScreen(),
        const HomeworkTrackerScreen(),
        const NotificationsScreen(),
      ];
      items = [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Attendance'),
        const NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded), label: 'Homework'),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_rounded),
          ),
          label: 'Alerts',
        ),
      ];
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        destinations: items,
      ),
    );
  }
}
