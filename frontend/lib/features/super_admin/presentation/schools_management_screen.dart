import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/super_admin_models.dart';
import '../providers/super_admin_provider.dart';
import 'permission_matrix_screen.dart';

class SchoolsManagementScreen extends ConsumerStatefulWidget {
  const SchoolsManagementScreen({super.key});

  @override
  ConsumerState<SchoolsManagementScreen> createState() => _SchoolsManagementScreenState();
}

class _SchoolsManagementScreenState extends ConsumerState<SchoolsManagementScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).loadSchools();
    });
  }

  void _openAddSchoolSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _RegisterSchoolModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminProvider);
    final schools = state.schools.where((s) {
      final matchesFilter = _selectedFilter == 'ALL' || s.status == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.code.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'School Institutional Registry',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
            onPressed: () => ref.read(superAdminProvider.notifier).loadSchools(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: Text('Register School', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        onPressed: _openAddSchoolSheet,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by school name or code...',
                hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All (${state.schools.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('ACTIVE', 'Active (${state.schools.where((s) => s.isActive).length})'),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING', 'Pending (${state.schools.where((s) => s.isPending).length})'),
                const SizedBox(width: 8),
                _buildFilterChip('SUSPENDED', 'Suspended (${state.schools.where((s) => s.isSuspended).length})'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Schools List
          Expanded(
            child: state.isLoading && state.schools.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : schools.isEmpty
                    ? Center(
                        child: Text(
                          'No institutions match your search.',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: schools.length,
                        itemBuilder: (ctx, index) {
                          final school = schools[index];
                          return _buildSchoolCard(school);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildSchoolCard(SuperAdminSchoolModel school) {
    Color statusColor = AppColors.emerald;
    if (school.isPending) statusColor = AppColors.amber;
    if (school.isSuspended) statusColor = AppColors.rose;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Code: ${school.code} • ${school.board} Board • AY ${school.currentAcademicYear}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    school.status,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: statusColor),
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 20),

            Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Capacity: ${school.maxStudents} Students', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                const Icon(Icons.co_present_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${school.maxTeachers} Teachers', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 14),

            // Action Buttons Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (school.isPending) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose,
                      side: const BorderSide(color: AppColors.rose),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    onPressed: () => ref.read(superAdminProvider.notifier).updateSchoolStatus(school.id, 'REJECTED'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    onPressed: () => ref.read(superAdminProvider.notifier).updateSchoolStatus(school.id, 'ACTIVE'),
                  ),
                ] else if (school.isActive) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose,
                      side: const BorderSide(color: AppColors.rose),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(Icons.block_rounded, size: 16),
                    label: const Text('Suspend'),
                    onPressed: () => ref.read(superAdminProvider.notifier).updateSchoolStatus(school.id, 'SUSPENDED'),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Activate'),
                    onPressed: () => ref.read(superAdminProvider.notifier).updateSchoolStatus(school.id, 'ACTIVE'),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppColors.primaryLight),
                  tooltip: 'Configure Modules & Limits',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PermissionMatrixScreen(preSelectedSchoolId: school.id)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Modal with ROCK SOLID STICKY SUBMIT BUTTON: NEVER HIDDEN
class _RegisterSchoolModal extends ConsumerStatefulWidget {
  const _RegisterSchoolModal();

  @override
  ConsumerState<_RegisterSchoolModal> createState() => _RegisterSchoolModalState();
}

class _RegisterSchoolModalState extends ConsumerState<_RegisterSchoolModal> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _studentsCtrl = TextEditingController(text: '1000');
  final _teachersCtrl = TextEditingController(text: '80');
  String _board = 'CBSE';
  bool _submitting = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _codeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill School Name and Code')));
      return;
    }

    setState(() => _submitting = true);
    final success = await ref.read(superAdminProvider.notifier).createSchool({
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim().toUpperCase(),
      'board': _board,
      'contactEmail': _emailCtrl.text.trim(),
      'contactPhone': _phoneCtrl.text.trim(),
      'limits': {
        'maxStudents': int.tryParse(_studentsCtrl.text) ?? 1000,
        'maxTeachers': int.tryParse(_teachersCtrl.text) ?? 80,
      },
    });

    if (!mounted) return;
    setState(() => _submitting = false);
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
              const Icon(Icons.domain_add_rounded, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                'Register New School',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(color: AppColors.border),

          // Scrollable fields
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CustomTextField(controller: _nameCtrl, label: 'School Legal Name *', hint: 'e.g. DPS International'),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _codeCtrl, label: 'School Code *', hint: 'e.g. DPS-01'),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _emailCtrl, label: 'Contact Email', hint: 'admin@dps.edu'),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _phoneCtrl, label: 'Contact Phone', hint: '+91 9876543210'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(controller: _studentsCtrl, label: 'Max Students', hint: '1000'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(controller: _teachersCtrl, label: 'Max Teachers', hint: '80'),
                      ),
                    ],
                  ),
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
              text: 'Register School',
              icon: Icons.check_circle_rounded,
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
