import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/super_admin_models.dart';
import '../providers/super_admin_provider.dart';

class PermissionMatrixScreen extends ConsumerStatefulWidget {
  final String? preSelectedSchoolId;

  const PermissionMatrixScreen({super.key, this.preSelectedSchoolId});

  @override
  ConsumerState<PermissionMatrixScreen> createState() => _PermissionMatrixScreenState();
}

class _PermissionMatrixScreenState extends ConsumerState<PermissionMatrixScreen> {
  String? _selectedSchoolId;
  final _maxStudentsCtrl = TextEditingController(text: '1000');
  final _maxTeachersCtrl = TextEditingController(text: '80');
  final _maxStaffCtrl = TextEditingController(text: '40');
  final _storageMBCtrl = TextEditingController(text: '10240');

  final Map<String, bool> _modules = {
    'busTracking': true,
    'biometricAttendance': true,
    'feeManagement': true,
    'examResults': true,
    'studentAdmission': true,
    'leaveManagement': true,
    'dailySyllabus': true,
    'communication': true,
  };

  bool _isSaving = false;

  final List<Map<String, String>> _moduleMeta = [
    {'key': 'busTracking', 'title': 'GPS Bus Fleet & Live Tracking', 'subtitle': 'Real-time telemetry, trip status, route playback'},
    {'key': 'biometricAttendance', 'title': 'Biometric Attendance Devices', 'subtitle': 'TCP/IP biometric sync, faculty attendance, overrides'},
    {'key': 'feeManagement', 'title': 'Student Fee Management & Billing', 'subtitle': 'Online fee dues, invoices, concessions, payments'},
    {'key': 'examResults', 'title': 'Examination & Report Cards', 'subtitle': 'Grade entry, merit lists, publishing governance'},
    {'key': 'studentAdmission', 'title': 'Student Admission & Enrollment', 'subtitle': 'Registration workflows, capacity caps, student profiles'},
    {'key': 'leaveManagement', 'title': 'Teacher & Staff Leave System', 'subtitle': 'Leave requests, approval chains, balance tracking'},
    {'key': 'dailySyllabus', 'title': 'Daily Syllabus & Lesson Planner', 'subtitle': 'Subject lesson logs, chapter progression tracking'},
    {'key': 'communication', 'title': 'Parent-Teacher Communication', 'subtitle': 'Direct secure messaging, queries, parent engagement'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSchoolId = widget.preSelectedSchoolId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(superAdminProvider.notifier).loadSchools();
      final schools = ref.read(superAdminProvider).schools;
      if (_selectedSchoolId == null && schools.isNotEmpty) {
        _selectedSchoolId = schools.first.id;
      }
      _populateSchoolData();
    });
  }

  void _populateSchoolData() {
    if (_selectedSchoolId == null) return;
    final schools = ref.read(superAdminProvider).schools;
    final school = schools.firstWhere(
      (s) => s.id == _selectedSchoolId,
      orElse: () => schools.first,
    );

    setState(() {
      _maxStudentsCtrl.text = school.maxStudents.toString();
      _maxTeachersCtrl.text = school.maxTeachers.toString();
      _maxStaffCtrl.text = school.maxStaff.toString();
      _storageMBCtrl.text = school.storageLimitMB.toString();

      for (var key in _modules.keys) {
        _modules[key] = school.modules[key] == true;
      }
    });
  }

  Future<void> _handleSave() async {
    if (_selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an institution first')));
      return;
    }

    setState(() => _isSaving = true);

    final limits = {
      'maxStudents': int.tryParse(_maxStudentsCtrl.text) ?? 1000,
      'maxTeachers': int.tryParse(_maxTeachersCtrl.text) ?? 80,
      'maxStaff': int.tryParse(_maxStaffCtrl.text) ?? 40,
      'storageLimitMB': int.tryParse(_storageMBCtrl.text) ?? 10240,
    };

    final success = await ref.read(superAdminProvider.notifier).updateSchoolModulesAndLimits(
          schoolId: _selectedSchoolId!,
          modules: _modules,
          limits: limits,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emerald,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Permission Matrix & Quotas saved successfully!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminProvider);
    final schools = state.schools;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Permissions & Resource Ceilings',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      // CRITICAL: BOTTOM STICKY SUBMIT BAR - ALWAYS VISIBLE, NEVER HIDDEN!
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Save Permissions & Ceilings',
            icon: Icons.save_rounded,
            isLoading: _isSaving,
            onPressed: _handleSave,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Institution Picker
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: AppColors.primaryLight, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Target School Institution:',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                            child: Text(
                              '${s.name} (${s.code})',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSchoolId = val);
                          _populateSchoolData();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 1: Module Activation Toggles
            Text(
              'Modular Feature Permissions',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Enable or revoke access to modular capabilities for this institution.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            ..._moduleMeta.map((meta) {
              final key = meta['key']!;
              final isEnabled = _modules[key] ?? false;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isEnabled ? AppColors.primary.withOpacity(0.3) : AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta['title']!,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                          ),
                          Text(
                            meta['subtitle']!,
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _modules[key] = val),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Section 2: Resource & Enrolment Limits
            Text(
              'Enrolment & Storage Quotas',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Hard capacity limits automatically enforced when breached.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildLimitInput('Max Students', _maxStudentsCtrl, Icons.school_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLimitInput('Max Teachers', _maxTeachersCtrl, Icons.person_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLimitInput('Max Staff', _maxStaffCtrl, Icons.badge_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLimitInput('Storage (MB)', _storageMBCtrl, Icons.cloud_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitInput(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }
}
