import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../providers/admin_provider.dart';

class SchoolSettingsScreen extends ConsumerStatefulWidget {
  const SchoolSettingsScreen({super.key});

  @override
  ConsumerState<SchoolSettingsScreen> createState() => _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends ConsumerState<SchoolSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadSchoolSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditProfileModal(BuildContext context, Map<String, dynamic>? settings) {
    final nameCtrl = TextEditingController(text: settings?['schoolName'] ?? 'St. Xavier International Academy');
    final codeCtrl = TextEditingController(text: settings?['affiliationCode'] ?? 'CBSE-DEL-2026-9812');
    final addrCtrl = TextEditingController(text: settings?['address'] ?? 'Plot 14, Institutional Area, Sector 62, New Delhi');
    final phoneCtrl = TextEditingController(text: settings?['phone'] ?? '+91 98765 43210');
    final emailCtrl = TextEditingController(text: settings?['email'] ?? 'admin@school.com');
    final sessionCtrl = TextEditingController(text: settings?['currentSession'] ?? '2026-2027');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Institution Profile',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              CustomTextField(controller: nameCtrl, label: 'Institution Name'),
              const SizedBox(height: 12),
              CustomTextField(controller: codeCtrl, label: 'Affiliation / Registration Code'),
              const SizedBox(height: 12),
              CustomTextField(controller: addrCtrl, label: 'Campus Address'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: CustomTextField(controller: phoneCtrl, label: 'Contact Phone')),
                  const SizedBox(width: 12),
                  Expanded(child: CustomTextField(controller: sessionCtrl, label: 'Academic Session')),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(controller: emailCtrl, label: 'Official Email'),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Save Institution Settings',
                onPressed: () async {
                  final ok = await ref.read(adminProvider.notifier).updateSchoolSettings({
                    'schoolName': nameCtrl.text.trim(),
                    'affiliationCode': codeCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'currentSession': sessionCtrl.text.trim(),
                  });

                  if (mounted) {
                    Navigator.pop(ctx);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Institution profile updated successfully!'),
                          backgroundColor: AppColors.emerald,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final settings = adminState.schoolSettings;
    final busRoutes = settings?['busRoutes'] as List? ?? [];
    final libraryBooks = settings?['libraryBooks'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'School & Operations Settings',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Institution Profile'),
            Tab(text: 'Transport Fleet'),
            Tab(text: 'Library Catalog'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Institution Profile Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        settings?['schoolName'] ?? 'St. Xavier International Academy',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Affiliation: ${settings?['affiliationCode'] ?? 'CBSE-DEL-2026-9812'}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      _buildInfoRow(Icons.location_on_outlined, 'Address', settings?['address'] ?? 'New Delhi'),
                      _buildInfoRow(Icons.phone_outlined, 'Phone', settings?['phone'] ?? '+91 98765 43210'),
                      _buildInfoRow(Icons.email_outlined, 'Email', settings?['email'] ?? 'admin@school.com'),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Session', settings?['currentSession'] ?? '2026-2027'),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Edit School Profile',
                        onPressed: () => _showEditProfileModal(context, settings),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Transport Fleet Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Active Bus Routes & Drivers', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                if (busRoutes.isEmpty)
                  const EmptyState(icon: Icons.directions_bus_outlined, title: 'No Bus Routes', message: 'Fleet will appear here.')
                else
                  ...busRoutes.map((b) {
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.directions_bus_rounded, color: AppColors.amber, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b['routeName'] ?? 'Bus Route', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('Bus #${b['busNumber']} • Driver: ${b['driverName']} (${b['driverPhone']})',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text('Capacity: ${b['studentCount'] ?? 0} / ${b['capacity']} students',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          // 3. Library Catalog Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Campus Library Catalog & Textbooks', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                if (libraryBooks.isEmpty)
                  const EmptyState(icon: Icons.menu_book_outlined, title: 'No Books Listed', message: 'Catalog will appear here.')
                else
                  ...libraryBooks.map((bk) {
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bk['title'] ?? 'Book', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('Author: ${bk['author']} • Category: ${bk['category']}',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text('Available: ${bk['availableCopies']} / ${bk['totalCopies']} copies',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
