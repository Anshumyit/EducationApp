import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/teacher_provider.dart';

class DailySyllabusTrackerScreen extends ConsumerStatefulWidget {
  final String? initialClassId;
  final String? initialSubject;

  const DailySyllabusTrackerScreen({
    super.key,
    this.initialClassId,
    this.initialSubject,
  });

  @override
  ConsumerState<DailySyllabusTrackerScreen> createState() => _DailySyllabusTrackerScreenState();
}

class _DailySyllabusTrackerScreenState extends ConsumerState<DailySyllabusTrackerScreen> {
  String? _selectedClassId;
  String _selectedSubject = 'Mathematics';
  String _selectedStatusFilter = 'ALL'; // ALL, COMPLETED, PARTIALLY_COMPLETED, PENDING
  bool _isLoading = false;

  final List<String> _defaultSubjects = [
    'Mathematics',
    'Science',
    'English',
    'Social Science',
    'Hindi',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Sanskrit',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
    });
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(teacherProvider.notifier);
    final teacherState = ref.read(teacherProvider);

    // 1. Fetch available classes
    final classes = await notifier.fetchAvailableClasses();

    // Determine initial selected class
    if (widget.initialClassId != null) {
      _selectedClassId = widget.initialClassId;
    } else if (teacherState.classInfo?['classroom']?['_id'] != null) {
      _selectedClassId = teacherState.classInfo!['classroom']['_id'];
    } else if (classes.isNotEmpty) {
      _selectedClassId = classes.first['_id'];
    }

    if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
      _selectedSubject = widget.initialSubject!;
    }

    await _loadLogsAndOverview();
    setState(() => _isLoading = false);
  }

  Future<void> _loadLogsAndOverview() async {
    final notifier = ref.read(teacherProvider.notifier);
    await Future.wait([
      notifier.fetchSyllabusOverview(classId: _selectedClassId, subject: _selectedSubject),
      notifier.fetchSyllabusLogs(
        classId: _selectedClassId,
        subject: _selectedSubject,
        status: _selectedStatusFilter == 'ALL' ? null : _selectedStatusFilter,
      ),
    ]);
  }

  List<String> _getSubjectsForSelectedClass(List<dynamic> classes) {
    if (_selectedClassId == null) return _defaultSubjects;
    final cls = classes.firstWhere(
      (c) => c['_id'] == _selectedClassId,
      orElse: () => null,
    );
    if (cls != null && cls['subjects'] is List && (cls['subjects'] as List).isNotEmpty) {
      final names = (cls['subjects'] as List)
          .map((s) => s is Map ? (s['name']?.toString() ?? '') : s.toString())
          .where((name) => name.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        // Merge with defaults to ensure variety
        final set = {...names, ..._defaultSubjects};
        return set.toList();
      }
    }
    return _defaultSubjects;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppColors.emerald;
      case 'PARTIALLY_COMPLETED':
        return AppColors.amber;
      case 'PENDING':
        return AppColors.rose;
      default:
        return AppColors.primary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Completed ✅';
      case 'PARTIALLY_COMPLETED':
        return 'Partially Done ⏳';
      case 'PENDING':
        return 'Pending 📌';
      default:
        return status;
    }
  }

  void _showAddOrEditLogModal({Map<String, dynamic>? existingLog}) {
    final isEdit = existingLog != null;
    final chapterController = TextEditingController(text: existingLog?['chapter'] ?? '');
    final topicController = TextEditingController(text: existingLog?['topic'] ?? '');
    final targetController = TextEditingController(text: existingLog?['dailyTarget'] ?? '');
    final nextTargetController = TextEditingController(text: existingLog?['nextClassTarget'] ?? '');
    final durationController = TextEditingController(text: '${existingLog?['durationMinutes'] ?? 45}');
    final notesController = TextEditingController(text: existingLog?['notes'] ?? '');

    // Material Controllers
    final materialTitleController = TextEditingController();
    final materialUrlController = TextEditingController();
    String materialType = 'PDF';

    List<Map<String, dynamic>> materials = existingLog?['studyMaterials'] != null
        ? List<Map<String, dynamic>>.from(
            (existingLog!['studyMaterials'] as List).map((m) => Map<String, dynamic>.from(m)))
        : [];

    String modalStatus = existingLog?['status'] ?? 'COMPLETED';
    double modalCompletionPct = (existingLog?['completionPercentage'] as num?)?.toDouble() ?? 50.0;
    DateTime selectedDate = existingLog?['date'] != null
        ? DateTime.tryParse(existingLog!['date']) ?? DateTime.now()
        : DateTime.now();

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final mediaQuery = MediaQuery.of(modalCtx);

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: mediaQuery.viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit Syllabus Log' : "Log Today's Syllabus & Target",
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$_selectedSubject • ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),

                    const Divider(color: AppColors.border, height: 24),

                    // Date Picker Row
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: modalCtx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
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
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.accent),
                                const SizedBox(width: 10),
                                Text(
                                  'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            const Text('Change', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Aaj ka Topic & Chapter
                    CustomTextField(
                      controller: chapterController,
                      label: 'Aaj ka Chapter (Chapter Name / No.)',
                      hint: 'e.g. Chapter 4: Quadratic Equations',
                      prefixIcon: Icons.menu_book_rounded,
                    ),

                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: topicController,
                      label: 'Aaj ka Topic',
                      hint: 'e.g. Deriving Quadratic Formula & Solving Roots',
                      prefixIcon: Icons.auto_stories_rounded,
                    ),

                    const SizedBox(height: 14),

                    // Aaj ka Target
                    CustomTextField(
                      controller: targetController,
                      label: 'Aaj ka Target (Class Goal)',
                      hint: 'e.g. Solve Ex 4.2 Q1 to Q10 with board demonstration',
                      prefixIcon: Icons.flag_rounded,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 18),

                    // Completion Status ChoiceChips
                    Text(
                      'Completion Status',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildStatusChoiceChip(
                          label: 'Completed ✅',
                          status: 'COMPLETED',
                          color: AppColors.emerald,
                          isSelected: modalStatus == 'COMPLETED',
                          onSelected: () => setModalState(() => modalStatus = 'COMPLETED'),
                        ),
                        _buildStatusChoiceChip(
                          label: 'Partially Completed ⏳',
                          status: 'PARTIALLY_COMPLETED',
                          color: AppColors.amber,
                          isSelected: modalStatus == 'PARTIALLY_COMPLETED',
                          onSelected: () => setModalState(() => modalStatus = 'PARTIALLY_COMPLETED'),
                        ),
                        _buildStatusChoiceChip(
                          label: 'Pending 📌',
                          status: 'PENDING',
                          color: AppColors.rose,
                          isSelected: modalStatus == 'PENDING',
                          onSelected: () => setModalState(() => modalStatus = 'PENDING'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Kitna Syllabus Complete Hua (%) Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kitna Syllabus Complete Hua (%)',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryLight),
                          ),
                          child: Text(
                            '${modalCompletionPct.round()}% Completed',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(modalCtx).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surfaceLight,
                        thumbColor: AppColors.accent,
                        overlayColor: AppColors.accent.withOpacity(0.2),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: modalCompletionPct,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (val) => setModalState(() => modalCompletionPct = val),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Padhane Mein Kitna Time Laga (Duration in Minutes)
                    Text(
                      'Padhane mein kitna time laga (Duration)',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final mins in [30, 45, 60, 90]) ...[
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                durationController.text = '$mins';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: durationController.text == '$mins'
                                    ? AppColors.primary.withOpacity(0.25)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: durationController.text == '$mins'
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                '$mins m',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: durationController.text == '$mins'
                                      ? AppColors.primaryLight
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: TextFormField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              hintText: 'Custom mins',
                              suffixText: 'mins',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Agli Class Ka Target
                    CustomTextField(
                      controller: nextTargetController,
                      label: 'Agli Class Ka Target (Next Class Goal)',
                      hint: 'e.g. Word problems on discriminant and nature of roots',
                      prefixIcon: Icons.rocket_launch_rounded,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 18),

                    // Study Materials & Notes Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
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
                                  const Icon(Icons.attach_file_rounded, color: AppColors.accent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Notes, PDF & Study Material',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${materials.length} attached',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Render existing materials list
                          if (materials.isNotEmpty) ...[
                            for (int i = 0; i < materials.length; i++) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      materials[i]['fileType'] == 'PDF'
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.link_rounded,
                                      size: 16,
                                      color: materials[i]['fileType'] == 'PDF'
                                          ? AppColors.rose
                                          : AppColors.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            materials[i]['title'] ?? 'Material',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            materials[i]['fileUrl'] ?? '',
                                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.rose),
                                      onPressed: () {
                                        setModalState(() {
                                          materials.removeAt(i);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                          ],

                          // Material Input Form
                          TextFormField(
                            controller: materialTitleController,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              hintText: 'Material Title (e.g. Formula Sheet PDF)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: materialUrlController,
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    hintText: 'Link / Google Drive / PDF URL',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final title = materialTitleController.text.trim();
                                  final url = materialUrlController.text.trim();
                                  if (title.isEmpty || url.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Enter both material title and URL')),
                                    );
                                    return;
                                  }
                                  setModalState(() {
                                    materials.add({
                                      'title': title,
                                      'fileUrl': url,
                                      'fileType': materialType,
                                    });
                                    materialTitleController.clear();
                                    materialUrlController.clear();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Additional Teacher Notes
                    CustomTextField(
                      controller: notesController,
                      label: 'Teacher Personal Notes / Remarks',
                      hint: 'e.g. Students found derivation challenging, need 10 min recap next day',
                      prefixIcon: Icons.edit_note_rounded,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Save / Update Button
                    CustomButton(
                      text: isEdit ? 'Update Syllabus Log' : 'Save Daily Syllabus & Target',
                      icon: isEdit ? Icons.save_rounded : Icons.check_circle_rounded,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final chapter = chapterController.text.trim();
                              final topic = topicController.text.trim();
                              final target = targetController.text.trim();
                              final duration = int.tryParse(durationController.text.trim()) ?? 45;

                              if (chapter.isEmpty || topic.isEmpty || target.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill Chapter, Topic, and Aaj ka Target'),
                                    backgroundColor: AppColors.rose,
                                  ),
                                );
                                return;
                              }

                              if (_selectedClassId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a class first'),
                                    backgroundColor: AppColors.rose,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              bool success = false;
                              final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

                              if (isEdit) {
                                success = await ref.read(teacherProvider.notifier).updateDailySyllabusLog(
                                      logId: existingLog['_id'],
                                      data: {
                                        'chapter': chapter,
                                        'topic': topic,
                                        'dailyTarget': target,
                                        'status': modalStatus,
                                        'completionPercentage': modalCompletionPct.round(),
                                        'durationMinutes': duration,
                                        'nextClassTarget': nextTargetController.text.trim(),
                                        'studyMaterials': materials,
                                        'notes': notesController.text.trim(),
                                        'date': dateStr,
                                      },
                                      classId: _selectedClassId,
                                      subject: _selectedSubject,
                                    );
                              } else {
                                success = await ref.read(teacherProvider.notifier).createDailySyllabusLog(
                                      classId: _selectedClassId!,
                                      subject: _selectedSubject,
                                      date: dateStr,
                                      chapter: chapter,
                                      topic: topic,
                                      dailyTarget: target,
                                      status: modalStatus,
                                      completionPercentage: modalCompletionPct,
                                      durationMinutes: duration,
                                      nextClassTarget: nextTargetController.text.trim(),
                                      studyMaterials: materials,
                                      notes: notesController.text.trim(),
                                    );
                              }

                              if (modalCtx.mounted) Navigator.pop(modalCtx);

                              if (mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.emerald,
                                      content: Text(
                                        isEdit
                                            ? 'Daily Syllabus Log updated successfully! 🎯'
                                            : "Today's Syllabus & Target recorded! 🎯",
                                      ),
                                    ),
                                  );
                                  await _loadLogsAndOverview();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.rose,
                                      content: Text('Failed to save syllabus log. Please retry.'),
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

  Widget _buildStatusChoiceChip({
    required String label,
    required String status,
    required Color color,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withOpacity(0.25),
      backgroundColor: AppColors.surfaceLight,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? color : AppColors.textSecondary,
      ),
      side: BorderSide(color: isSelected ? color : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Future<void> _deleteLog(String logId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Syllabus Log', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to remove this daily target log?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ref.read(teacherProvider.notifier).deleteDailySyllabusLog(
            logId: logId,
            classId: _selectedClassId,
            subject: _selectedSubject,
          );
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: AppColors.emerald, content: Text('Syllabus log deleted')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: AppColors.rose, content: Text('Failed to delete log')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherProvider);
    final availableClasses = teacherState.availableClasses;
    final syllabusOverview = teacherState.syllabusOverview;
    final logs = teacherState.syllabusLogs;

    final subjectList = _getSubjectsForSelectedClass(availableClasses);

    // Calculate current subject stats
    final subjectProgressList = (syllabusOverview?['subjectProgress'] as List<dynamic>?) ?? [];
    final currentSubProgress = subjectProgressList.firstWhere(
      (s) => (s['subject'] as String?)?.toLowerCase() == _selectedSubject.toLowerCase(),
      orElse: () => null,
    );

    final completionPct = (currentSubProgress?['latestPercentage'] as num?)?.toDouble() ?? 0.0;
    final totalHours = syllabusOverview?['totalTeachingHours'] ?? '0.0';
    final totalLectures = currentSubProgress?['totalLectures'] ?? logs.length;
    final breakdown = syllabusOverview?['statusBreakdown'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Syllabus & Target Tracker',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'Lesson Plans • Daily Targets • Material Upload',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: _loadLogsAndOverview,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLogsAndOverview,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Class & Subject Selectors Card
              _buildClassAndSubjectSelector(availableClasses, subjectList),

              const SizedBox(height: 16),

              // 2. Syllabus Progress & Analytics Card
              _buildProgressOverviewCard(
                completionPct: completionPct,
                totalHours: totalHours.toString(),
                totalLectures: totalLectures.toString(),
                breakdown: breakdown,
                lastChapter: currentSubProgress?['lastChapter'],
                lastTopic: currentSubProgress?['lastTopic'],
                nextTarget: currentSubProgress?['nextTarget'],
              ),

              const SizedBox(height: 18),

              // 3. Action Button: "Log Today's Class & Target"
              CustomButton(
                text: "Log Today's Class & Target",
                icon: Icons.add_task_rounded,
                onPressed: () => _showAddOrEditLogModal(),
              ),

              const SizedBox(height: 20),

              // 4. Status Filter Pills
              _buildFilterChips(),

              const SizedBox(height: 14),

              // 5. Daily Syllabus Logs List / History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Classroom Lecture Log (${logs.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$_selectedSubject History',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (logs.isEmpty) ...[
                _buildEmptyState(),
              ] else ...[
                for (final log in logs) ...[
                  _buildLogCard(log),
                  const SizedBox(height: 12),
                ],
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassAndSubjectSelector(List<dynamic> classes, List<String> subjects) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.class_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Select Class & Subject',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Class Dropdown
          if (classes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClassId,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accent),
                  hint: Text(
                    'Choose Class',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  items: classes.map<DropdownMenuItem<String>>((cls) {
                    final name = '${cls['name']} - ${cls['section']}';
                    return DropdownMenuItem<String>(
                      value: cls['_id'],
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newClassId) {
                    if (newClassId != null && newClassId != _selectedClassId) {
                      setState(() {
                        _selectedClassId = newClassId;
                      });
                      _loadLogsAndOverview();
                    }
                  },
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Class 10 - A (Primary Class)',
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Horizontal Subject Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subjects.map((subj) {
                final isSelected = subj.toLowerCase() == _selectedSubject.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(subj),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedSubject = subj);
                      _loadLogsAndOverview();
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryLight : AppColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverviewCard({
    required double completionPct,
    required String totalHours,
    required String totalLectures,
    Map<String, dynamic>? breakdown,
    String? lastChapter,
    String? lastTopic,
    String? nextTarget,
  }) {
    final completedCount = breakdown?['completed'] ?? 0;
    final partialCount = breakdown?['partiallyCompleted'] ?? 0;
    final pendingCount = breakdown?['pending'] ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      gradient: AppColors.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedSubject Syllabus Progress',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Overall syllabus tracked across lectures',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${completionPct.round()}% Done',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (completionPct / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
            ),
          ),

          const SizedBox(height: 16),

          // Stats Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.play_lesson_rounded,
                  label: 'Lectures',
                  value: totalLectures,
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.timer_rounded,
                  label: 'Hours Taught',
                  value: '${totalHours}h',
                  color: AppColors.primaryLight,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Completed',
                  value: '$completedCount',
                  color: AppColors.emerald,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.hourglass_top_rounded,
                  label: 'In-Progress',
                  value: '$partialCount',
                  color: AppColors.amber,
                ),
              ),
            ],
          ),

          if (nextTarget != null && nextTarget.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rocket_launch_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Agla Target: ',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                  Expanded(
                    child: Text(
                      nextTarget,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'ALL', 'label': 'All Logs'},
      {'key': 'COMPLETED', 'label': 'Completed ✅'},
      {'key': 'PARTIALLY_COMPLETED', 'label': 'Partially Done ⏳'},
      {'key': 'PENDING', 'label': 'Pending 📌'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatusFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedStatusFilter = f['key']!);
                _loadLogsAndOverview();
              },
              selectedColor: AppColors.primary.withOpacity(0.3),
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.primaryLight : AppColors.border,
              ),
              labelStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final status = log['status'] ?? 'COMPLETED';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final duration = log['durationMinutes'] ?? 45;
    final completionPct = log['completionPercentage'] ?? 0;
    final materials = (log['studyMaterials'] as List<dynamic>?) ?? [];
    final dateStr = log['date'] ?? '';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Date, Subject Pill, Duration, Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateStr,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$duration mins',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                color: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showAddOrEditLogModal(existingLog: log);
                  } else if (val == 'delete') {
                    _deleteLog(log['_id']);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text('Edit Log', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.rose),
                        const SizedBox(width: 8),
                        Text('Delete', style: GoogleFonts.inter(color: AppColors.rose)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Chapter & Topic
          Text(
            log['chapter'] ?? 'Chapter',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            log['topic'] ?? 'Topic',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          // Aaj Ka Target
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_rounded, size: 16, color: AppColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aaj Ka Target:',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.amber,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        log['dailyTarget'] ?? '',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Agli Class Ka Target (if any)
          if (log['nextClassTarget'] != null && (log['nextClassTarget'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rocket_launch_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agli Class Ka Target:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log['nextClassTarget'],
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Progress & Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Syllabus: $completionPct%',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),

          // Study Materials Links / Badges
          if (materials.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: materials.map<Widget>((mat) {
                final title = mat['title'] ?? 'Material';
                final url = mat['fileUrl'] ?? '';
                final isPdf = mat['fileType'] == 'PDF';

                return InkWell(
                  onTap: () {
                    // Copy URL to clipboard
                    if (url.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied link: $url'),
                          backgroundColor: AppColors.surfaceElevated,
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isPdf ? AppColors.rose.withOpacity(0.12) : AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPdf ? AppColors.rose.withOpacity(0.3) : AppColors.accent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPdf ? Icons.picture_as_pdf_rounded : Icons.link_rounded,
                          size: 14,
                          color: isPdf ? AppColors.rose : AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPdf ? AppColors.rose : AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded, size: 11, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Notes (if any)
          if (log['notes'] != null && (log['notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Remarks: ${log['notes']}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories_rounded, size: 36, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 14),
          Text(
            'No Syllabus Logs Recorded Yet',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track your daily teaching topics, syllabus %, and next targets for $_selectedSubject by logging your first class.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddOrEditLogModal(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Log First Lecture'),
          ),
        ],
      ),
    );
  }
}
