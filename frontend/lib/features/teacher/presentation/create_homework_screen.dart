import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/teacher_provider.dart';

class CreateHomeworkScreen extends ConsumerStatefulWidget {
  const CreateHomeworkScreen({super.key});

  @override
  ConsumerState<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends ConsumerState<CreateHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController(text: 'Mathematics');
  DateTime _submissionDate = DateTime.now().add(const Duration(days: 3));
  bool _isSubmitting = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _submissionDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _submissionDate = picked);
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final teacherState = ref.read(teacherProvider);
    final classId = teacherState.classInfo?['classroom']?['_id'];

    if (classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Classroom information is missing')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final ok = await ref.read(teacherProvider.notifier).createHomework(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          subject: _subjectController.text.trim(),
          classId: classId,
          submissionDate: _submissionDate,
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Homework assigned & instant notification sent to all parents! 📚'),
        ),
      );
      Navigator.pop(context);
    } else {
      final err = ref.read(teacherProvider).errorMessage ?? 'Failed to assign homework';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.rose, content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDueDate = DateFormat('EEEE, MMM d, yyyy').format(_submissionDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assign New Homework'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _subjectController,
                  label: 'Academic Subject',
                  hint: 'e.g. Mathematics, Science, English',
                  prefixIcon: Icons.menu_book_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Subject is required' : null,
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _titleController,
                  label: 'Assignment Title',
                  hint: 'e.g. Chapter 5 Linear Equations Ex 5.1',
                  prefixIcon: Icons.title_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _descController,
                  label: 'Detailed Instructions & Questions',
                  hint: 'Explain the tasks, page numbers, or questions to solve...',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: 20),

                // Submission Deadline Picker
                Text(
                  'Submission Deadline (Due Date)',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.accent),
                            const SizedBox(width: 12),
                            Text(
                              formattedDueDate,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Push Alert Guarantee Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 24, color: AppColors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Publishing will instantly trigger a push notification to every registered parent of this class.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                CustomButton(
                  text: 'Publish Homework & Notify Parents',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _handleCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
