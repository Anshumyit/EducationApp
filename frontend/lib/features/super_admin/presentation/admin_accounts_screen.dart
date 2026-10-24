import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../models/super_admin_models.dart';
import '../providers/super_admin_provider.dart';

class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  ConsumerState<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends ConsumerState<AdminAccountsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).loadAdmins();
      ref.read(superAdminProvider.notifier).loadSchools();
    });
  }

  void _openCreateAdminSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateAdminModal(),
    );
  }

  void _openPermissionsModal(SuperAdminUserModel admin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminPermissionsModal(admin: admin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminProvider);
    final admins = state.admins.where((a) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return a.name.toLowerCase().contains(q) ||
          (a.email != null && a.email!.toLowerCase().contains(q)) ||
          (a.schoolName != null && a.schoolName!.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'School Administrators',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
            onPressed: () => ref.read(superAdminProvider.notifier).loadAdmins(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.purple,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text('Create Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        onPressed: _openCreateAdminSheet,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search administrator by name, email or school...',
                hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          Expanded(
            child: state.isLoading && state.admins.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : admins.isEmpty
                    ? Center(
                        child: Text(
                          'No administrator accounts found.',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: admins.length,
                        itemBuilder: (ctx, index) {
                          final admin = admins[index];
                          return _buildAdminCard(admin);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(SuperAdminUserModel admin) {
    final isSuspended = admin.isSuspended;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSuspended ? AppColors.rose.withOpacity(0.3) : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.purple.withOpacity(0.2),
                  child: Text(
                    admin.name.isNotEmpty ? admin.name[0] : 'A',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.purple),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      Text(
                        admin.schoolName ?? 'Unassigned Campus',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isSuspended ? AppColors.rose : AppColors.emerald).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSuspended ? 'SUSPENDED' : 'ACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSuspended ? AppColors.rose : AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 20),

            Row(
              children: [
                const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(admin.email ?? 'N/A', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(admin.phone ?? 'N/A', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSuspended ? AppColors.emerald : AppColors.rose,
                    side: BorderSide(color: isSuspended ? AppColors.emerald : AppColors.rose),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: Icon(isSuspended ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 16),
                  label: Text(isSuspended ? 'Unsuspend' : 'Suspend'),
                  onPressed: () => ref.read(superAdminProvider.notifier).updateAdminStatus(admin.id, !isSuspended),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.vpn_key_rounded, size: 16),
                  label: const Text('Permissions'),
                  onPressed: () => _openPermissionsModal(admin),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Create Admin Modal with STICKY SUBMIT BUTTON: NEVER HIDDEN
class _CreateAdminModal extends ConsumerStatefulWidget {
  const _CreateAdminModal();

  @override
  ConsumerState<_CreateAdminModal> createState() => _CreateAdminModalState();
}

class _CreateAdminModalState extends ConsumerState<_CreateAdminModal> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: 'Password@123');
  String? _selectedSchoolId;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill Name, Email and assign School')));
      return;
    }

    setState(() => _submitting = true);
    final success = await ref.read(superAdminProvider.notifier).createAdmin({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'schoolId': _selectedSchoolId,
    });

    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schools = ref.watch(superAdminProvider).schools;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: AppColors.purple),
              const SizedBox(width: 8),
              Text(
                'Create School Admin',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(color: AppColors.border),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assign School Institution *', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSchoolId,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        hint: Text('Select School', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                        items: schools.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(s.name, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSchoolId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(controller: _nameCtrl, label: 'Full Name *', hint: 'e.g. Dr. Rajesh Sharma'),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _emailCtrl, label: 'Official Email *', hint: 'principal@school.edu'),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _phoneCtrl, label: 'Mobile Number', hint: '9876543210'),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _passwordCtrl, label: 'Initial Password', hint: '••••••••', isPassword: true),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // STICKY BOTTOM SUBMIT BUTTON (ALWAYS VISIBLE, NEVER HIDDEN)
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: CustomButton(
              text: 'Create Administrator Account',
              icon: Icons.person_add_rounded,
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

// Permissions Modal with STICKY SUBMIT BUTTON: NEVER HIDDEN
class _AdminPermissionsModal extends ConsumerStatefulWidget {
  final SuperAdminUserModel admin;

  const _AdminPermissionsModal({required this.admin});

  @override
  ConsumerState<_AdminPermissionsModal> createState() => _AdminPermissionsModalState();
}

class _AdminPermissionsModalState extends ConsumerState<_AdminPermissionsModal> {
  final Map<String, bool> _perms = {};
  bool _saving = false;

  final List<Map<String, String>> _permList = [
    {'key': 'canCreateTeachers', 'label': 'Create & Onboard Teachers'},
    {'key': 'canApproveUsers', 'label': 'Approve Teacher & Parent Accounts'},
    {'key': 'canManageFees', 'label': 'Collect Fees & Generate Slips'},
    {'key': 'canPublishExams', 'label': 'Publish Examination Marks'},
    {'key': 'canSendBroadcasts', 'label': 'Transmit Notices & Circulars'},
    {'key': 'canEditClassrooms', 'label': 'Manage Classes & Sections'},
    {'key': 'canExportData', 'label': 'Export Reports (Excel/CSV)'},
    {'key': 'canManageSalary', 'label': 'Generate Staff Salary Slips'},
  ];

  @override
  void initState() {
    super.initState();
    for (var p in _permList) {
      _perms[p['key']!] = widget.admin.permissions[p['key']!] != false;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await ref.read(superAdminProvider.notifier).updateAdminPermissions(widget.admin.id, _perms);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, color: AppColors.purple),
              const SizedBox(width: 8),
              Text(
                'Admin Permissions Matrix',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Text(
            widget.admin.name,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(color: AppColors.border),

          Expanded(
            child: ListView(
              children: _permList.map((p) {
                final key = p['key']!;
                final isChecked = _perms[key] ?? true;
                return CheckboxListTile(
                  title: Text(p['label']!, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                  value: isChecked,
                  activeColor: AppColors.purple,
                  checkColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _perms[key] = val ?? false),
                );
              }).toList(),
            ),
          ),

          // STICKY BOTTOM SUBMIT BUTTON (ALWAYS VISIBLE, NEVER HIDDEN)
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: CustomButton(
              text: 'Save Permissions Matrix',
              icon: Icons.check_circle_rounded,
              isLoading: _saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
