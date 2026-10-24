import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/teacher_provider.dart';

class HomeworkManagementScreen extends ConsumerStatefulWidget {
  const HomeworkManagementScreen({super.key});

  @override
  ConsumerState<HomeworkManagementScreen> createState() => _HomeworkManagementScreenState();
}

class _HomeworkManagementScreenState extends ConsumerState<HomeworkManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Assignment List State
  List<dynamic> _homeworkList = [];
  bool _isLoadingList = false;

  // Create Assignment Form State
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController(text: 'Mathematics');
  final _maxMarksController = TextEditingController(text: '20');
  final _instructionsController = TextEditingController();
  DateTime _submissionDate = DateTime.now().add(const Duration(days: 3));
  bool _isSubmitting = false;

  // Attachment controls
  final _attachmentTitleController = TextEditingController();
  final _attachmentUrlController = TextEditingController();
  String _attachmentType = 'DOCUMENT';
  final List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClassHomework();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    _maxMarksController.dispose();
    _instructionsController.dispose();
    _attachmentTitleController.dispose();
    _attachmentUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadClassHomework() async {
    setState(() => _isLoadingList = true);
    final teacherState = ref.read(teacherProvider);
    final classId = teacherState.classInfo?['classroom']?['_id'];

    if (classId != null) {
      final list = await ref.read(teacherProvider.notifier).fetchClassHomework(classId);
      setState(() {
        _homeworkList = list;
        _isLoadingList = false;
      });
    } else {
      setState(() => _isLoadingList = false);
    }
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

  Future<void> _handleCreateHomework() async {
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
          maxMarks: int.tryParse(_maxMarksController.text.trim()) ?? 20,
          instructions: _instructionsController.text.trim(),
          attachments: _attachments,
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Homework published & instant notification sent to all parents! 📚'),
        ),
      );
      // Reset form
      _titleController.clear();
      _descController.clear();
      _instructionsController.clear();
      setState(() {
        _attachments.clear();
        _submissionDate = DateTime.now().add(const Duration(days: 3));
      });
      _tabController.animateTo(0);
      _loadClassHomework();
    } else {
      final err = ref.read(teacherProvider).errorMessage ?? 'Failed to assign homework';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.rose, content: Text(err)),
      );
    }
  }

  void _openSubmissionsReviewModal(Map<String, dynamic> homework) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkSubmissionsScreen(homework: homework),
      ),
    ).then((_) => _loadClassHomework());
  }

  Future<void> _deleteHomework(String homeworkId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Assignment', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete this homework? All student submissions will be permanently removed.',
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
      final ok = await ref.read(teacherProvider.notifier).deleteHomework(homeworkId);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: AppColors.emerald, content: Text('Homework deleted successfully')),
          );
          _loadClassHomework();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: AppColors.rose, content: Text('Failed to delete homework')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Homework & Assignments', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Track Submissions, Grade & Send Feedback', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.assignment_rounded, size: 18), text: 'Class Assignments'),
            Tab(icon: Icon(Icons.add_task_rounded, size: 18), text: 'Assign Homework'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentsListTab(),
          _buildCreateHomeworkTab(),
        ],
      ),
    );
  }

  Widget _buildAssignmentsListTab() {
    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_homeworkList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.primaryLight),
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Homework Assigned',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Create and publish homework for your class with attachments, last dates, and tracking.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Assign First Homework'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassHomework,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _homeworkList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final hw = _homeworkList[index];
          final stats = hw['stats'] as Map<String, dynamic>?;
          final totalStudents = stats?['totalStudents'] ?? 0;
          final submittedCount = stats?['submittedCount'] ?? 0;
          final gradedCount = stats?['gradedCount'] ?? 0;
          final pendingCount = stats?['pendingCount'] ?? 0;
          final lateCount = stats?['lateCount'] ?? 0;

          final submissionDateStr = hw['submissionDate'] != null
              ? DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(hw['submissionDate']))
              : '';
          final attachments = (hw['attachments'] as List<dynamic>?) ?? [];

          return GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Subject, Deadline, Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        hw['subject'] ?? 'Subject',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 14, color: AppColors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Due: $submissionDateStr',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.amber, fontWeight: FontWeight.w600),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                          color: AppColors.surfaceElevated,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (val) {
                            if (val == 'delete') _deleteHomework(hw['_id']);
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.rose),
                                  SizedBox(width: 8),
                                  Text('Delete Homework', style: TextStyle(color: AppColors.rose)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Title
                Text(
                  hw['title'] ?? 'Homework Title',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  hw['description'] ?? '',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Attachments Chips
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: attachments.map<Widget>((att) {
                      final title = att['title'] ?? 'Document';
                      final type = att['fileType'] ?? 'DOCUMENT';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type == 'PDF'
                                  ? Icons.picture_as_pdf_rounded
                                  : (type == 'IMAGE' ? Icons.image_rounded : Icons.attachment_rounded),
                              size: 12,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(title, style: GoogleFonts.inter(fontSize: 11, color: AppColors.accent)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),

                // Submissions Progress Counters
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Total', '$totalStudents', AppColors.textPrimary),
                      _buildStatColumn('Submitted', '$submittedCount', AppColors.emerald),
                      _buildStatColumn('Graded', '$gradedCount', AppColors.purple),
                      _buildStatColumn('Pending', '$pendingCount', AppColors.amber),
                      _buildStatColumn('Late', '$lateCount', AppColors.rose),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action: Review & Grade Submissions
                ElevatedButton.icon(
                  onPressed: () => _openSubmissionsReviewModal(hw),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.rate_review_rounded, size: 16),
                  label: Text(
                    'Review Submissions & Grade (${submittedCount}/$totalStudents)',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildCreateHomeworkTab() {
    final formattedDueDate = DateFormat('EEEE, MMM d, yyyy').format(_submissionDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: _subjectController,
              label: 'Academic Subject',
              hint: 'e.g. Mathematics, Science, English, Social Science',
              prefixIcon: Icons.menu_book_rounded,
              validator: (v) => v == null || v.isEmpty ? 'Subject is required' : null,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _titleController,
              label: 'Assignment Title',
              hint: 'e.g. Chapter 4 Quadratic Equations Exercise 4.2',
              prefixIcon: Icons.title_rounded,
              validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _descController,
              label: 'Detailed Instructions & Questions',
              hint: 'Explain the homework tasks, questions to solve, or book page numbers...',
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
              validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _maxMarksController,
                    label: 'Maximum Marks',
                    hint: '20',
                    prefixIcon: Icons.grade_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Due Date Picker
            Text(
              'Submission Deadline (Last Date)',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
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
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                            'Attach Photo, PDF ya Document',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Text('${_attachments.length} attached', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Existing attachments list
                  if (_attachments.isNotEmpty) ...[
                    for (int i = 0; i < _attachments.length; i++) ...[
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
                              _attachments[i]['fileType'] == 'PDF'
                                  ? Icons.picture_as_pdf_rounded
                                  : (_attachments[i]['fileType'] == 'IMAGE' ? Icons.image_rounded : Icons.link_rounded),
                              size: 16,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _attachments[i]['title'] ?? '',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
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
                    const SizedBox(height: 6),
                  ],

                  // Add Attachment form
                  TextFormField(
                    controller: _attachmentTitleController,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      hintText: 'Document Name (e.g. Chapter 4 Worksheet PDF)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _attachmentUrlController,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            hintText: 'Drive / PDF / Image URL Link',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          final title = _attachmentTitleController.text.trim();
                          final url = _attachmentUrlController.text.trim();
                          if (title.isEmpty || url.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter document title and URL')),
                            );
                            return;
                          }
                          setState(() {
                            final type = url.toLowerCase().endsWith('.pdf')
                                ? 'PDF'
                                : (url.toLowerCase().endsWith('.jpg') || url.toLowerCase().endsWith('.png') ? 'IMAGE' : 'DOCUMENT');
                            _attachments.add({'title': title, 'fileUrl': url, 'fileType': type});
                            _attachmentTitleController.clear();
                            _attachmentUrlController.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
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

            const SizedBox(height: 24),

            CustomButton(
              text: 'Publish Homework & Notify Parents',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _handleCreateHomework,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ================= Detailed Submissions Screen =================

class HomeworkSubmissionsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> homework;

  const HomeworkSubmissionsScreen({super.key, required this.homework});

  @override
  ConsumerState<HomeworkSubmissionsScreen> createState() => _HomeworkSubmissionsScreenState();
}

class _HomeworkSubmissionsScreenState extends ConsumerState<HomeworkSubmissionsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _filter = 'ALL'; // ALL, SUBMITTED, PENDING, LATE, GRADED

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    final res = await ref.read(teacherProvider.notifier).fetchHomeworkSubmissions(widget.homework['_id']);
    setState(() {
      _data = res;
      _isLoading = false;
    });
  }

  void _showGradeModal(Map<String, dynamic> studentItem) {
    final marksController = TextEditingController(text: studentItem['marksObtained']?.toString() ?? '');
    final feedbackController = TextEditingController(text: studentItem['feedback']?.toString() ?? '');
    String status = studentItem['status'] == 'RESUBMISSION_REQUESTED' ? 'RESUBMISSION_REQUESTED' : 'GRADED';
    final maxMarks = widget.homework['maxMarks'] ?? 20;
    bool isSaving = false;

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
                top: 20,
                bottom: mediaQuery.viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grade Student Homework',
                              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${studentItem['student']?['name']} (#${studentItem['student']?['rollNumber']})',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 20),

                    // Submitted attachments if any
                    if (studentItem['attachments'] is List && (studentItem['attachments'] as List).isNotEmpty) ...[
                      Text(
                        'Student Attached Work:',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: (studentItem['attachments'] as List).map<Widget>((att) {
                          return Chip(
                            avatar: const Icon(Icons.image_rounded, size: 14, color: AppColors.accent),
                            label: Text(att['title'] ?? 'Document', style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.surfaceLight,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Marks Input
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: marksController,
                            label: 'Marks Obtained (Out of $maxMarks)',
                            hint: 'e.g. 18',
                            prefixIcon: Icons.fact_check_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Feedback Input
                    CustomTextField(
                      controller: feedbackController,
                      label: 'Teacher Feedback & Remarks',
                      hint: 'e.g. Well done! Neat handwriting and accurate problem solving.',
                      prefixIcon: Icons.comment_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),

                    // Status Choices
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Grade & Pass ✅'),
                          selected: status == 'GRADED',
                          selectedColor: AppColors.emerald.withOpacity(0.25),
                          onSelected: (_) => setModalState(() => status = 'GRADED'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Ask Resubmission 🔄'),
                          selected: status == 'RESUBMISSION_REQUESTED',
                          selectedColor: AppColors.rose.withOpacity(0.25),
                          onSelected: (_) => setModalState(() => status = 'RESUBMISSION_REQUESTED'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Save Marks & Notify Parent',
                      icon: Icons.check_circle_rounded,
                      isLoading: isSaving,
                      onPressed: isSaving
                          ? null
                          : () async {
                              final marks = double.tryParse(marksController.text.trim());
                              if (marks == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter valid marks')),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              final ok = await ref.read(teacherProvider.notifier).gradeHomeworkSubmission(
                                    homeworkId: widget.homework['_id'],
                                    studentId: studentItem['student']['_id'],
                                    marksObtained: marks,
                                    feedback: feedbackController.text.trim(),
                                    status: status,
                                  );

                              if (ctx.mounted) Navigator.pop(ctx);

                              if (mounted) {
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.emerald,
                                      content: Text('Homework checked & parent notified! 📝'),
                                    ),
                                  );
                                  _loadSubmissions();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.rose,
                                      content: Text('Failed to save grade'),
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ));
          },
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    final summary = _data?['summary'] as Map<String, dynamic>?;
    final roster = (_data?['roster'] as List<dynamic>?) ?? [];

    final filteredRoster = roster.where((item) {
      if (_filter == 'ALL') return true;
      if (_filter == 'SUBMITTED') return item['hasSubmitted'] == true;
      if (_filter == 'PENDING') return item['hasSubmitted'] == false;
      if (_filter == 'LATE') return item['isLate'] == true;
      if (_filter == 'GRADED') return item['status'] == 'GRADED';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.homework['title'] ?? 'Submissions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${widget.homework['subject']} • Max Marks: ${widget.homework['maxMarks'] ?? 20}',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadSubmissions),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubmissions,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Overview Summary Card
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCountMetric('Total', '${summary?['totalStudents'] ?? 0}', AppColors.textPrimary),
                          _buildCountMetric('Submitted', '${summary?['submittedCount'] ?? 0}', AppColors.emerald),
                          _buildCountMetric('Graded', '${summary?['gradedCount'] ?? 0}', AppColors.purple),
                          _buildCountMetric('Pending', '${summary?['pendingCount'] ?? 0}', AppColors.amber),
                          _buildCountMetric('Late', '${summary?['lateCount'] ?? 0}', AppColors.rose),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in [
                            {'k': 'ALL', 'l': 'All Students'},
                            {'k': 'SUBMITTED', 'l': 'Submitted ✅'},
                            {'k': 'PENDING', 'l': 'Pending ⏳'},
                            {'k': 'LATE', 'l': 'Late ⚠️'},
                            {'k': 'GRADED', 'l': 'Graded 📝'},
                          ]) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f['l']!),
                                selected: _filter == f['k'],
                                onSelected: (_) => setState(() => _filter = f['k']!),
                                selectedColor: AppColors.primary.withOpacity(0.25),
                                backgroundColor: AppColors.surface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Students List
                    for (final item in filteredRoster) ...[
                      _buildStudentSubmissionCard(item),
                      const SizedBox(height: 10),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCountMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStudentSubmissionCard(Map<String, dynamic> item) {
    final student = item['student'] ?? {};
    final hasSubmitted = item['hasSubmitted'] == true;
    final isLate = item['isLate'] == true;
    final status = item['status'] ?? 'PENDING';
    final marks = item['marksObtained'];
    final feedback = item['feedback'] as String?;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              student['name'] != null && (student['name'] as String).isNotEmpty
                  ? (student['name'] as String)[0].toUpperCase()
                  : 'S',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      student['name'] ?? 'Student',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (isLate)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Late ⚠️', style: GoogleFonts.inter(fontSize: 10, color: AppColors.rose, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                Text('Roll No: #${student['rollNumber'] ?? '-'}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),

                const SizedBox(height: 6),

                // Status Pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hasSubmitted ? AppColors.emerald.withOpacity(0.15) : AppColors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hasSubmitted ? 'Submitted ✅' : 'Pending ⏳',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: hasSubmitted ? AppColors.emerald : AppColors.amber,
                        ),
                      ),
                    ),
                    if (marks != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Marks: $marks/${widget.homework['maxMarks'] ?? 20}',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple),
                      ),
                    ],
                  ],
                ),

                if (feedback != null && feedback.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Remark: "$feedback"',
                      style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _showGradeModal(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: marks != null ? AppColors.surfaceElevated : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(marks != null ? 'Edit' : 'Grade', style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
