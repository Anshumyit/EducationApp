import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/super_admin_provider.dart';
import 'admin_accounts_screen.dart';
import 'biometric_devices_screen.dart';
import 'bus_fleet_screen.dart';
import 'central_broadcast_screen.dart';
import 'permission_matrix_screen.dart';
import 'schools_management_screen.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).loadDashboard();
      ref.read(superAdminProvider.notifier).loadSchools();
      ref.read(superAdminProvider.notifier).loadAdmins();
      ref.read(superAdminProvider.notifier).loadBuses();
      ref.read(superAdminProvider.notifier).loadBiometricDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(superAdminProvider);
    final stats = state.dashboardStats;

    final kpi = stats?['kpiStats'];
    final schoolStatus = stats?['schoolsStatus'];
    final financial = stats?['financialSummary'];
    final busAlerts = (stats?['busAlerts'] as List?) ?? [];
    final recentAudits = (stats?['recentAudits'] as List?) ?? [];

    final totalSchools = kpi?['totalSchools'] ?? state.schools.length;
    final activeSchools = schoolStatus?['active'] ?? state.schools.where((s) => s.isActive).length;
    final pendingSchools = schoolStatus?['pending'] ?? state.schools.where((s) => s.isPending).length;
    final suspendedSchools = schoolStatus?['suspended'] ?? state.schools.where((s) => s.isSuspended).length;

    final totalUsers = (kpi?['totalAdmins'] ?? 0) + (kpi?['totalTeachers'] ?? 0) + (kpi?['totalStudents'] ?? 0);
    final activeBuses = kpi?['activeBuses'] ?? state.buses.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'Super Administrator',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Master Platform Controller • Session 2026-27',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.purple.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, size: 14, color: AppColors.purple),
                const SizedBox(width: 4),
                Text('SUPER ADMIN', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.purple)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
            tooltip: 'Refresh Platform Data',
            onPressed: () {
              ref.read(superAdminProvider.notifier).loadDashboard();
              ref.read(superAdminProvider.notifier).loadSchools();
              ref.read(superAdminProvider.notifier).loadAdmins();
              ref.read(superAdminProvider.notifier).loadBuses();
              ref.read(superAdminProvider.notifier).loadBiometricDevices();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(superAdminProvider.notifier).loadDashboard();
          await ref.read(superAdminProvider.notifier).loadSchools();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top KPI Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  StatCard(
                    title: 'Total Schools',
                    value: '$totalSchools',
                    icon: Icons.school_rounded,
                    color: AppColors.primary,
                    subtitle: '$activeSchools Active • $pendingSchools Pending',
                  ),
                  StatCard(
                    title: 'Total Network Users',
                    value: '$totalUsers',
                    icon: Icons.groups_rounded,
                    color: AppColors.emerald,
                    subtitle: '${kpi?['totalAdmins'] ?? 0} Admins • ${kpi?['totalTeachers'] ?? 0} Staff',
                  ),
                  StatCard(
                    title: 'Bus Fleet GPS',
                    value: '$activeBuses',
                    icon: Icons.directions_bus_rounded,
                    color: AppColors.amber,
                    subtitle: '${busAlerts.length} Expiry Alerts',
                  ),
                  StatCard(
                    title: 'Fee Collection',
                    value: '₹${((financial?['totalCollected'] ?? 0) / 1000).toStringAsFixed(1)}k',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.purple,
                    subtitle: '₹${((financial?['totalPending'] ?? 0) / 1000).toStringAsFixed(1)}k Pending',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Module Quick Navigation
              Text(
                'Platform Governance Controls',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      context,
                      title: 'Schools Registry',
                      subtitle: '$totalSchools Campus records',
                      icon: Icons.domain_rounded,
                      color: AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolsManagementScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      context,
                      title: 'School Admins',
                      subtitle: '${state.admins.length} Principals',
                      icon: Icons.admin_panel_settings_rounded,
                      color: AppColors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAccountsScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      context,
                      title: 'Permissions & Ceilings',
                      subtitle: 'Modules & Quotas',
                      icon: Icons.tune_rounded,
                      color: AppColors.emerald,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionMatrixScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      context,
                      title: 'Bus Fleet & GPS',
                      subtitle: '$activeBuses Vehicles Live',
                      icon: Icons.gps_fixed_rounded,
                      color: AppColors.amber,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusFleetScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      context,
                      title: 'Biometric Devices',
                      subtitle: '${state.biometricDevices.length} Terminals',
                      icon: Icons.fingerprint_rounded,
                      color: Colors.tealAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BiometricDevicesScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      context,
                      title: 'Central Broadcast',
                      subtitle: 'Multi-school circulars',
                      icon: Icons.campaign_rounded,
                      color: AppColors.rose,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CentralBroadcastScreen())),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Platform Audit Activity
              Text(
                'Recent Master Audit Trail',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              if (recentAudits.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No recent administrative audit records.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ...recentAudits.take(5).map((log) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history_rounded, size: 16, color: AppColors.primaryLight),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['action']?.toString().replaceAll('_', ' ') ?? 'ACTION',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                                ),
                                Text(
                                  'By ${log['performedByName'] ?? 'Super Admin'} • ${log['schoolName'] ?? 'Platform'}',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log['status'] ?? 'SUCCESS',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald),
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
