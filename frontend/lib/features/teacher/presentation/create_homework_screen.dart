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
  final List<Map<String, dynamic>> _attachments = [];

  void _showUploadAttachmentSheet({String initialType = 'PDF'}) {
    String selectedType = initialType;
    final titleController = TextEditingController(
      text: selectedType == 'PDF'
          ? '${_subjectController.text.trim()} Worksheet.pdf'
          : '${_subjectController.text.trim()} Question Paper.jpg',
    );
    final urlController = TextEditingController();

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selectedType == 'PDF'
                                ? AppColors.rose.withOpacity(0.15)
                                : AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selectedType == 'PDF'
                                ? Icons.picture_as_pdf_rounded
                                : Icons.image_rounded,
                            color: selectedType == 'PDF' ? AppColors.rose : AppColors.accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload ${selectedType == 'PDF' ? 'PDF Document' : 'Photo / Image'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Attach worksheet or questions for students',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Toggle Type: PDF vs IMAGE
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedType = 'PDF';
                                if (titleController.text.isEmpty ||
                                    titleController.text.endsWith('.jpg') ||
                                    titleController.text.endsWith('.png')) {
                                  titleController.text = '${_subjectController.text.trim()} Worksheet.pdf';
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == 'PDF' ? AppColors.rose.withOpacity(0.2) : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedType == 'PDF' ? AppColors.rose : AppColors.border,
                                  width: selectedType == 'PDF' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.rose),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PDF Document',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: selectedType == 'PDF' ? AppColors.rose : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedType = 'IMAGE';
                                if (titleController.text.isEmpty || titleController.text.endsWith('.pdf')) {
                                  titleController.text = '${_subjectController.text.trim()} Questions.jpg';
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == 'IMAGE' ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedType == 'IMAGE' ? AppColors.accent : AppColors.border,
                                  width: selectedType == 'IMAGE' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.image_rounded, size: 16, color: AppColors.accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Photo / Image',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: selectedType == 'IMAGE' ? AppColors.accent : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: titleController,
                      label: selectedType == 'PDF' ? 'PDF Document Title' : 'Image / Photo Title',
                      hint: selectedType == 'PDF' ? 'e.g. Chapter 4 Worksheet.pdf' : 'e.g. Exercise Page.jpg',
                      prefixIcon: selectedType == 'PDF' ? Icons.description_rounded : Icons.photo_size_select_actual_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Quick Presets
                    Text(
                      'Choose Common Template or File Name:',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (selectedType == 'PDF'
                              ? [
                                  '📄 ${_subjectController.text} Worksheet.pdf',
                                  '📑 Practice Questions Sheet.pdf',
                                  '📖 Chapter Formulas.pdf',
                                ]
                              : [
                                  '📸 Textbook Page Photo.jpg',
                                  '🖼️ Homework Question Sheet.png',
                                  '📝 Handwritten Notes.jpg',
                                ])
                          .map(
                            (preset) => InkWell(
                              onTap: () {
                                setModalState(() {
                                  final clean = preset.substring(2).trim();
                                  titleController.text = clean;
                                  if (urlController.text.isEmpty) {
                                    final safeFile = clean.replaceAll(' ', '_');
                                    urlController.text = 'https://scholarcloud.storage/homework/$safeFile';
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  preset,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: urlController,
                      label: 'File / Cloud Link / Device Path',
                      hint: selectedType == 'PDF'
                          ? 'e.g. https://drive.google.com/file/... or /uploads/doc.pdf'
                          : 'e.g. https://images.unsplash.com/... or /uploads/photo.jpg',
                      prefixIcon: Icons.link_rounded,
                    ),
                    const SizedBox(height: 20),

                    CustomButton(
                      text: 'Upload & Attach to Homework',
                      icon: Icons.check_circle_rounded,
                      onPressed: () {
                        var title = titleController.text.trim();
                        var url = urlController.text.trim();

                        if (title.isEmpty) {
                          title = selectedType == 'PDF'
                              ? '${_subjectController.text.trim()} Worksheet.pdf'
                              : '${_subjectController.text.trim()} Question Paper.jpg';
                        }

                        if (url.isEmpty) {
                          final safeName = title.replaceAll(' ', '_');
                          url = selectedType == 'PDF'
                              ? 'https://scholarcloud.storage/homework/$safeName'
                              : 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=800&q=80';
                        }

                        setState(() {
                          _attachments.add({
                            'title': title,
                            'fileUrl': url,
                            'fileType': selectedType,
                          });
                        });

                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.emerald,
                            content: Text('$title ($selectedType) attached successfully! 📎'),
                          ),
                        );
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
          attachments: _attachments,
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

                const SizedBox(height: 20),

                // Attachments Section (Photo, PDF, Documents)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.attach_file_rounded, color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Attachments (PDF & Photos)',
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _attachments.isNotEmpty ? AppColors.emerald.withOpacity(0.15) : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_attachments.length} attached',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _attachments.isNotEmpty ? AppColors.emerald : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Direct 1-Tap Upload Buttons for PDF & Image
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showUploadAttachmentSheet(initialType: 'PDF'),
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.white),
                              label: const Text('Upload PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.rose,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showUploadAttachmentSheet(initialType: 'IMAGE'),
                              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18, color: Colors.white),
                              label: const Text('Upload Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Existing attachments list
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        for (int i = 0; i < _attachments.length; i++) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _attachments[i]['fileType'] == 'PDF'
                                        ? AppColors.rose.withOpacity(0.15)
                                        : AppColors.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    _attachments[i]['fileType'] == 'PDF'
                                        ? Icons.picture_as_pdf_rounded
                                        : (_attachments[i]['fileType'] == 'IMAGE' ? Icons.image_rounded : Icons.link_rounded),
                                    size: 16,
                                    color: _attachments[i]['fileType'] == 'PDF' ? AppColors.rose : AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _attachments[i]['title'] ?? '',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        '${_attachments[i]['fileType']} • Ready to publish',
                                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.rose),
                                  onPressed: () => setState(() => _attachments.removeAt(i)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
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
