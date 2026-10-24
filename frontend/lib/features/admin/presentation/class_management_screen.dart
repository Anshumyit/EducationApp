import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/admin_provider.dart';

class ClassManagementScreen extends ConsumerStatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  ConsumerState<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends ConsumerState<ClassManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadClasses();
      ref.read(adminProvider.notifier).loadDashboard(); // for teachers list
    });
  }

  void _showCreateClassModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'Class 11');
    final sectionCtrl = TextEditingController(text: 'A');
    final roomCtrl = TextEditingController(text: 'Room 301');
    final capacityCtrl = TextEditingController(text: '40');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final mediaQuery = MediaQuery.of(ctx);
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: mediaQuery.viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Class & Section',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Supports Nursery, LKG, UKG, Class 1 to Class 12 with sections (A, B, C)',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: nameCtrl,
                      label: 'Class Name (e.g. Nursery, Class 9, Class 12)',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(controller: sectionCtrl, label: 'Section (e.g. A, B, C)'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(controller: roomCtrl, label: 'Room Number'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: capacityCtrl,
                      label: 'Student Capacity',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Create Class',
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty || sectionCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill class name and section'),
                                    backgroundColor: AppColors.rose,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final ok = await ref.read(adminProvider.notifier).createClassRoom({
                                'name': nameCtrl.text.trim(),
                                'section': sectionCtrl.text.trim().toUpperCase(),
                                'roomNumber': roomCtrl.text.trim(),
                                'capacity': int.tryParse(capacityCtrl.text.trim()) ?? 40,
                              });

                              if (mounted) {
                                Navigator.pop(ctx);
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Class & Section created successfully!'),
                                      backgroundColor: AppColors.emerald,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ref.read(adminProvider).errorMessage ?? 'Failed to create class'),
                                      backgroundColor: AppColors.rose,
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
        },
      ),
    );
  }

  void _showAssignTeacherModal(BuildContext context, dynamic classroom) {
    final teachers = ref.read(adminProvider).teachers;
    String? selectedTeacher = classroom['classTeacher']?['_id'] ?? (teachers.isNotEmpty ? teachers.first['_id'] : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Assign Class Teacher',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign primary class teacher for ${classroom['name']} - ${classroom['section']}',
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
                    value: selectedTeacher,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    hint: const Text('Select Teacher'),
                    items: teachers.map<DropdownMenuItem<String>>((t) {
                      return DropdownMenuItem<String>(
                        value: t['_id'],
                        child: Text(
                          '${t['name']} (${(t['subjects'] as List? ?? []).join(", ")})',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedTeacher = val),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (selectedTeacher == null) return;
                Navigator.pop(ctx);
                final ok = await ref.read(adminProvider.notifier).assignClassTeacher(
                      classroom['_id'],
                      selectedTeacher!,
                    );
                if (mounted) {
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Class teacher assigned successfully!'),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ref.read(adminProvider).errorMessage ?? 'Failed to assign class teacher'),
                        backgroundColor: AppColors.rose,
                      ),
                    );
                  }
                }
              },
              child: const Text('Assign', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimetableModal(BuildContext context, dynamic classroom) {
    final subjects = classroom['subjects'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${classroom['name']} - ${classroom['section']} Curriculum & Schedule',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Standard academic timetable & subject periods',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Assigned Subjects (${subjects.length}):',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (subjects.isNotEmpty
                          ? subjects.map((s) => s['name'].toString()).toList()
                          : ['Mathematics', 'English', 'Science', 'Social Studies', 'Hindi'])
                      .map(
                        (s) => Chip(
                          backgroundColor: AppColors.surfaceVariant,
                          label: Text(s, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Daily Period Schedule (Sample):',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                ...[
                  {'period': 'Period 1 (08:30 - 09:15)', 'subject': 'Mathematics'},
                  {'period': 'Period 2 (09:15 - 10:00)', 'subject': 'Physics / Science'},
                  {'period': 'Period 3 (10:00 - 10:45)', 'subject': 'English Literature'},
                  {'period': 'Recess (10:45 - 11:15)', 'subject': 'Lunch Break 🥪'},
                  {'period': 'Period 4 (11:15 - 12:00)', 'subject': 'Social Studies / History'},
                  {'period': 'Period 5 (12:00 - 12:45)', 'subject': 'Computer Science / Lab'},
                ].map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p['period']!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                        Text(p['subject']!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Done',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final classes = adminState.classes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Classes & Timetable',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_home_work_rounded, color: Colors.white),
        label: Text('New Class', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => _showCreateClassModal(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(adminProvider.notifier).loadClasses(),
        child: classes.isEmpty
            ? const EmptyState(
                icon: Icons.meeting_room_outlined,
                title: 'No Classes Configured',
                message: 'Tap the button below to add your first class & section.',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final c = classes[index];
                  final teacher = c['classTeacher'];
                  final studentCount = c['studentCount'] ?? 0;
                  final capacity = c['capacity'] ?? 40;

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.class_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c['name']} - Section ${c['section']}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${c['roomNumber'] ?? 'Standard Hall'} • Capacity: $studentCount / $capacity students',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_pin_rounded, size: 18, color: AppColors.emerald),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  teacher != null
                                      ? 'Class Teacher: ${teacher['name']}'
                                      : 'Class Teacher: Unassigned',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: teacher != null ? AppColors.textPrimary : AppColors.amber,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _showAssignTeacherModal(context, c),
                                child: Text(
                                  teacher != null ? 'Change' : 'Assign',
                                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.schedule_rounded, size: 16, color: AppColors.accent),
                              label: const Text('Timetable & Periods', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                              onPressed: () => _showTimetableModal(context, c),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
