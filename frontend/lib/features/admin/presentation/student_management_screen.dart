import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class StudentManagementScreen extends ConsumerStatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  ConsumerState<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends ConsumerState<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClassId;
  String _selectedStatus = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadClasses();
      _fetchStudents();
    });
  }

  void _fetchStudents() {
    ref.read(adminProvider.notifier).loadStudents(
          classId: _selectedClassId,
          search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        );
  }

  void _showAddStudentModal(BuildContext context, {Map<String, dynamic>? studentToEdit}) {
    final nameCtrl = TextEditingController(text: studentToEdit?['name'] ?? '');
    final rollCtrl = TextEditingController(text: studentToEdit?['rollNumber']?.toString() ?? '');
    final admCtrl = TextEditingController(text: studentToEdit?['admissionNumber'] ?? '');
    final addressCtrl = TextEditingController(text: studentToEdit?['address'] ?? '');
    final emergencyCtrl = TextEditingController(text: studentToEdit?['emergencyContact'] ?? '');
    final dobCtrl = TextEditingController(
      text: studentToEdit?['dateOfBirth'] != null
          ? studentToEdit!['dateOfBirth'].toString().split('T')[0]
          : '2012-05-15',
    );
    String gender = studentToEdit?['gender'] ?? 'MALE';
    String bloodGroup = studentToEdit?['bloodGroup'] ?? 'O+';
    String? selectedClass = studentToEdit?['classId']?['_id'] ?? _selectedClassId;
    String? selectedParent = studentToEdit?['parentId']?['_id'];

    final classes = ref.read(adminProvider).classes;
    if (selectedClass == null && classes.isNotEmpty) {
      selectedClass = classes.first['_id'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        studentToEdit == null ? 'Enroll New Student' : 'Edit Student Profile',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(controller: nameCtrl, label: 'Full Student Name'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: rollCtrl,
                          label: 'Roll Number',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: admCtrl,
                          label: 'Admission # (Auto if empty)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Class Selection Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedClass,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        hint: Text('Select Class & Section', style: GoogleFonts.inter(color: AppColors.textMuted)),
                        items: classes.map<DropdownMenuItem<String>>((c) {
                          return DropdownMenuItem<String>(
                            value: c['_id'],
                            child: Text(
                              '${c['name']} - ${c['section']}',
                              style: GoogleFonts.inter(color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedClass = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(controller: dobCtrl, label: 'DOB (YYYY-MM-DD)'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: bloodGroup,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((bg) {
                                return DropdownMenuItem(
                                  value: bg,
                                  child: Text('Blood: $bg', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                                );
                              }).toList(),
                              onChanged: (val) => setModalState(() => bloodGroup = val!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(controller: addressCtrl, label: 'Residential Address'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: emergencyCtrl,
                    label: 'Emergency / Guardian Phone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: studentToEdit == null ? 'Enroll Student' : 'Save Changes',
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || selectedClass == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter student name and choose a class')),
                        );
                        return;
                      }

                      // Resolve parent ID if not selected (fallback to first parent user or creator)
                      final parentId = selectedParent ??
                          studentToEdit?['parentId']?['_id'] ??
                          '650000000000000000000004'; // fallback ID for demo parent

                      final payload = {
                        'name': nameCtrl.text.trim(),
                        'rollNumber': int.tryParse(rollCtrl.text.trim()) ?? 1,
                        'admissionNumber': admCtrl.text.trim().isNotEmpty ? admCtrl.text.trim() : null,
                        'classId': selectedClass,
                        'parentId': parentId,
                        'dateOfBirth': dobCtrl.text.trim(),
                        'gender': gender,
                        'bloodGroup': bloodGroup,
                        'address': addressCtrl.text.trim().isNotEmpty
                            ? addressCtrl.text.trim()
                            : 'Delhi Campus Enclave',
                        'emergencyContact': emergencyCtrl.text.trim().isNotEmpty
                            ? emergencyCtrl.text.trim()
                            : '9876543214',
                      };

                      bool ok;
                      if (studentToEdit == null) {
                        ok = await ref.read(adminProvider.notifier).createStudent(payload);
                      } else {
                        ok = await ref
                            .read(adminProvider.notifier)
                            .updateStudent(studentToEdit['_id'], payload);
                      }

                      if (mounted) {
                        Navigator.pop(ctx);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                studentToEdit == null
                                    ? 'Student enrolled successfully!'
                                    : 'Student profile updated!',
                              ),
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
          );
        },
      ),
    );
  }

  void _showTCModal(BuildContext context, dynamic student) {
    final reasonCtrl = TextEditingController(text: 'Course completed / Relocation');
    final tcNumCtrl = TextEditingController(text: 'TC-${DateTime.now().year}-${student['rollNumber']}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Issue Transfer Certificate (TC)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Issuing formal TC for ${student['name']} (${student['admissionNumber']}). This will update status to TC Issued.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: tcNumCtrl, label: 'TC Serial Number'),
            const SizedBox(height: 12),
            CustomTextField(controller: reasonCtrl, label: 'Reason for Leaving'),
          ],
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
              final ok = await ref.read(adminProvider.notifier).updateStudentStatus(
                    student['_id'],
                    'TC_ISSUED',
                    tcNumber: tcNumCtrl.text.trim(),
                    tcReason: reasonCtrl.text.trim(),
                  );
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transfer Certificate generated and student status updated!'),
                    backgroundColor: AppColors.rose,
                  ),
                );
              }
            },
            child: const Text('Issue TC', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPromoteModal(BuildContext context, dynamic student) {
    final classes = ref.read(adminProvider).classes;
    String? targetClass = classes.isNotEmpty ? classes.first['_id'] : null;
    final sessionCtrl = TextEditingController(text: '2026-2027');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Promote Student',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Promote ${student['name']} to the next class for the new academic session.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: targetClass,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    items: classes.map<DropdownMenuItem<String>>((c) {
                      return DropdownMenuItem<String>(
                        value: c['_id'],
                        child: Text('${c['name']} - ${c['section']}', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => targetClass = val),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(controller: sessionCtrl, label: 'Academic Session'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
              onPressed: () async {
                if (targetClass == null) return;
                Navigator.pop(ctx);
                final ok = await ref.read(adminProvider.notifier).promoteStudents(
                      [student['_id']],
                      targetClass!,
                      session: sessionCtrl.text.trim(),
                    );
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student successfully promoted to next class!'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                }
              },
              child: const Text('Promote', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final students = adminState.students;
    final classes = adminState.classes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Student Management',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Enroll Student', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => _showAddStudentModal(context),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by student name, roll # or adm #...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              _fetchStudents();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onSubmitted: (_) => _fetchStudents(),
                ),
                const SizedBox(height: 10),

                // Class Filter horizontal chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedClassId == null,
                        label: Text('All Classes', style: GoogleFonts.inter(fontSize: 12)),
                        onSelected: (sel) {
                          setState(() => _selectedClassId = null);
                          _fetchStudents();
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      ...classes.map((cls) {
                        final isSel = _selectedClassId == cls['_id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSel,
                            label: Text('${cls['name']} - ${cls['section']}', style: GoogleFonts.inter(fontSize: 12)),
                            onSelected: (sel) {
                              setState(() => _selectedClassId = sel ? cls['_id'] : null);
                              _fetchStudents();
                            },
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Students List or Loading
          Expanded(
            child: adminState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                    ? const EmptyState(
                        icon: Icons.school_outlined,
                        title: 'No Students Found',
                        message: 'Try adjusting your filters or enroll a new student.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchStudents(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final status = student['status'] ?? 'ACTIVE';
                            final isTC = status == 'TC_ISSUED';

                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.surfaceVariant,
                                        backgroundImage: student['photo'] != null
                                            ? NetworkImage(student['photo'])
                                            : null,
                                        child: student['photo'] == null
                                            ? Text(
                                                (student['name'] ?? 'S')[0],
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    student['name'] ?? 'Unknown Student',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                StatusBadge(
                                                  status: status,
                                                  color: isTC
                                                      ? AppColors.rose
                                                      : status == 'ACTIVE'
                                                          ? AppColors.emerald
                                                          : AppColors.amber,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Roll #${student['rollNumber']} • Adm: ${student['admissionNumber']} • ${student['classId'] != null ? "${student['classId']['name']} - ${student['classId']['section']}" : "Class Unassigned"}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Guardian: ${student['parentId']?['name'] ?? "Guardian"} • Contact: ${student['emergencyContact'] ?? "N/A"}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: AppColors.border, height: 20),
                                  // Quick Action Bar
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                        label: const Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                        onPressed: () => _showAddStudentModal(context, studentToEdit: student),
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton.icon(
                                        icon: const Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.emerald),
                                        label: const Text('Promote', style: TextStyle(color: AppColors.emerald, fontSize: 12)),
                                        onPressed: () => _showPromoteModal(context, student),
                                      ),
                                      const SizedBox(width: 4),
                                      if (!isTC)
                                        TextButton.icon(
                                          icon: const Icon(Icons.assignment_returned_outlined, size: 16, color: AppColors.amber),
                                          label: const Text('TC', style: TextStyle(color: AppColors.amber, fontSize: 12)),
                                          onPressed: () => _showTCModal(context, student),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rose),
                                        tooltip: 'Delete Student',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: AppColors.surface,
                                              title: const Text('Delete Student?'),
                                              content: Text('Are you sure you want to permanently remove ${student['name']}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            ref.read(adminProvider.notifier).deleteStudent(student['_id']);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
