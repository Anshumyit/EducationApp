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

class TeacherDirectoryScreen extends ConsumerWidget {
  const TeacherDirectoryScreen({super.key});

  void _showSalarySlipDialog(BuildContext context, WidgetRef ref, dynamic teacher) {
    final monthController = TextEditingController(text: 'October');
    final yearController = TextEditingController(text: '2026');
    final basicController = TextEditingController(text: (teacher['salary'] ?? 50000).toString());
    final hraController = TextEditingController(text: '8000');
    final daController = TextEditingController(text: '3000');
    final pfController = TextEditingController(text: '3500');
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
                left: 24,
                right: 24,
                top: 24,
                bottom: mediaQuery.viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Generate Salary Slip',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generating pay slip for ${teacher['name']}',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(controller: monthController, label: 'Month'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: yearController,
                            label: 'Year',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: basicController,
                      label: 'Basic Salary (₹)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: hraController,
                            label: 'HRA (₹)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: daController,
                            label: 'DA (₹)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: pfController,
                      label: 'PF Deduction (₹)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Issue Salary Slip & Notify Teacher',
                      icon: Icons.receipt_long_rounded,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final ok = await ref.read(adminProvider.notifier).generateSalarySlip(
                                    teacherId: teacher['_id'],
                                    month: monthController.text.trim(),
                                    year: int.tryParse(yearController.text) ?? 2026,
                                    basicSalary: double.tryParse(basicController.text) ?? 50000,
                                    hra: double.tryParse(hraController.text) ?? 0,
                                    da: double.tryParse(daController.text) ?? 0,
                                    pfDeduction: double.tryParse(pfController.text) ?? 0,
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.emerald,
                                      content: Text('Salary slip issued for ${teacher['name']}!'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.rose,
                                      content: Text(
                                        ref.read(adminProvider).errorMessage ?? 'Failed to issue salary slip',
                                      ),
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

  void _showAddTeacherDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: 'Dr. Vivek Sharma');
    final emailCtrl = TextEditingController(text: 'vivek.teacher@school.com');
    final phoneCtrl = TextEditingController(text: '+91 98765 12340');
    final subjectsCtrl = TextEditingController(text: 'Mathematics, Science');
    final qualCtrl = TextEditingController(text: 'M.Sc, B.Ed');
    final salaryCtrl = TextEditingController(text: '55000');
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
                      'Add Faculty / Staff Profile',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Register teaching faculty with qualification and salary records',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(controller: nameCtrl, label: 'Faculty Name'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: CustomTextField(controller: emailCtrl, label: 'Email Address')),
                        const SizedBox(width: 12),
                        Expanded(child: CustomTextField(controller: phoneCtrl, label: 'Phone Number')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(controller: subjectsCtrl, label: 'Subjects (comma-separated)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: CustomTextField(controller: qualCtrl, label: 'Highest Qualification')),
                        const SizedBox(width: 12),
                        Expanded(child: CustomTextField(controller: salaryCtrl, label: 'Monthly Salary (₹)', keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Add Faculty Member',
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter faculty name and email address'),
                                    backgroundColor: AppColors.rose,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final ok = await ref.read(adminProvider.notifier).createTeacher({
                                'name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '+91 9876543210',
                                'subjects': subjectsCtrl.text.split(',').map((s) => s.trim()).toList(),
                                'qualification': qualCtrl.text.trim(),
                                'salary': double.tryParse(salaryCtrl.text.trim()) ?? 55000,
                              });

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Faculty profile created successfully!'),
                                      backgroundColor: AppColors.emerald,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ref.read(adminProvider).errorMessage ?? 'Failed to add faculty member',
                                      ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final teachers = adminState.teachers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Faculty & Teacher Directory'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Add Teacher', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => _showAddTeacherDialog(context, ref),
      ),
      body: teachers.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No Teachers Found',
              description: 'There are currently no registered faculty members.',
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(adminProvider.notifier).loadDashboard(),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: teachers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final t = teachers[index];
                  final subjects = (t['subjects'] as List<dynamic>? ?? []);
                  final isClassTeacher = t['isClassTeacher'] == true;
                  final assignedClass = t['assignedClass'];

                  return GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                t['name'] != null && t['name'].toString().isNotEmpty
                                    ? t['name'][0].toUpperCase()
                                    : 'T',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['name'] ?? 'Teacher',
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t['qualification'] ?? t['email'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: t['status'] ?? 'ACTIVE'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Class Teacher Assignment Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isClassTeacher
                                ? AppColors.emerald.withOpacity(0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isClassTeacher
                                  ? AppColors.emerald.withOpacity(0.3)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isClassTeacher
                                    ? Icons.stars_rounded
                                    : Icons.assignment_ind_outlined,
                                size: 16,
                                color: isClassTeacher ? AppColors.emerald : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isClassTeacher
                                    ? 'Class Teacher: ${assignedClass != null ? (assignedClass['name'] ?? '') + ' - ' + (assignedClass['section'] ?? '') : 'Class Assigned'}'
                                    : 'Subject Teacher',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isClassTeacher ? AppColors.emerald : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subjects Taught
                        Text(
                          'Subjects Taught:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: subjects.isEmpty
                              ? [
                                  Text(
                                    'No subjects assigned',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                  )
                                ]
                              : subjects.map((sub) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      sub.toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                        ),
                        const SizedBox(height: 16),

                        if (t['status'] == 'PENDING') ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Approve Faculty',
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.emerald,
                                  height: 42,
                                  onPressed: () async {
                                    final ok = await ref
                                        .read(adminProvider.notifier)
                                        .updateApprovalStatus(t['_id'], 'APPROVED');
                                    if (context.mounted && ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.emerald,
                                          behavior: SnackBarBehavior.floating,
                                          content: Text('${t['name']} has been approved!'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomButton(
                                  text: 'Issue Slip',
                                  icon: Icons.payments_outlined,
                                  isOutlined: true,
                                  height: 42,
                                  onPressed: () => _showSalarySlipDialog(context, ref, t),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Salary Action
                          CustomButton(
                            text: 'Issue Salary Slip',
                            icon: Icons.payments_outlined,
                            isOutlined: true,
                            height: 42,
                            onPressed: () => _showSalarySlipDialog(context, ref, t),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
