import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/teacher_provider.dart';

class ParentCommunicationHubScreen extends ConsumerStatefulWidget {
  const ParentCommunicationHubScreen({super.key});

  @override
  ConsumerState<ParentCommunicationHubScreen> createState() => _ParentCommunicationHubScreenState();
}

class _ParentCommunicationHubScreenState extends ConsumerState<ParentCommunicationHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State
  List<dynamic> _announcements = [];
  List<dynamic> _meetings = [];
  List<dynamic> _queries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllCommunicationData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCommunicationData() async {
    setState(() => _isLoading = true);
    final teacherState = ref.read(teacherProvider);
    final classId = teacherState.classInfo?['classroom']?['_id'];
    final notifier = ref.read(teacherProvider.notifier);

    final futures = <Future>[
      notifier.fetchMeetings().then((list) => _meetings = list),
      notifier.fetchParentQueries().then((list) => _queries = list),
    ];

    if (classId != null) {
      futures.add(notifier.fetchClassAnnouncements(classId).then((list) => _announcements = list));
    }

    await Future.wait(futures);
    if (mounted) setState(() => _isLoading = false);
  }

  // ================= Direct Message Modal =================
  void _showDirectMessageModal(Map<String, dynamic> student) {
    final parent = student['parentId'];
    if (parent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No parent account linked to this student')),
      );
      return;
    }

    final messageController = TextEditingController();
    bool isSending = false;

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
                              'Message to Parent',
                              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${parent['name']} (Parent of ${student['name']})',
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

                    CustomTextField(
                      controller: messageController,
                      label: 'Direct Message',
                      hint: 'Type message to send directly to parent app...',
                      prefixIcon: Icons.chat_bubble_outline_rounded,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 20),

                    CustomButton(
                      text: 'Send Direct Message',
                      icon: Icons.send_rounded,
                      isLoading: isSending,
                      onPressed: isSending
                          ? null
                          : () async {
                              final text = messageController.text.trim();
                              if (text.isEmpty) return;

                              setModalState(() => isSending = true);

                              final ok = await ref.read(teacherProvider.notifier).sendDirectMessage(
                                    recipientId: parent['_id'],
                                    studentId: student['_id'],
                                    message: text,
                                  );

                              if (ctx.mounted) Navigator.pop(ctx);

                              if (mounted) {
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.emerald,
                                      content: Text('Message sent with Delivery status! 💬'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.rose,
                                      content: Text('Failed to deliver message'),
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

  // ================= Share Progress Modal =================
  void _showShareProgressModal(Map<String, dynamic> student) {
    final remarksController = TextEditingController(
      text: 'Good academic performance and regular attendance. Keep up the active participation.',
    );
    String grade = 'A';
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
                              'Share Student Progress Card',
                              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${student['name']} (#${student['rollNumber']})',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.emerald),
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

                    // Overall Grade selector
                    Text(
                      'Overall Term Grade',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['A+', 'A', 'B+', 'B', 'C'].map((g) {
                        return ChoiceChip(
                          label: Text(g),
                          selected: grade == g,
                          onSelected: (_) => setModalState(() => grade = g),
                          selectedColor: AppColors.emerald.withOpacity(0.25),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: remarksController,
                      label: 'Teacher Remarks & Behavioral Note',
                      hint: 'Personalized evaluation notes for parents...',
                      prefixIcon: Icons.edit_note_rounded,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Dispatch Progress Report to Parent',
                      icon: Icons.send_rounded,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);

                              final ok = await ref.read(teacherProvider.notifier).shareStudentProgress(
                                    studentId: student['_id'],
                                    overallGrade: grade,
                                    teacherRemarks: remarksController.text.trim(),
                                  );

                              if (ctx.mounted) Navigator.pop(ctx);

                              if (mounted) {
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.emerald,
                                      content: Text('Progress card delivered to parent app! 📊'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.rose,
                                      content: Text('Failed to share progress'),
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

  // ================= Schedule Meeting Modal =================
  void _showScheduleMeetingModal() {
    final students = ref.read(teacherProvider).students;
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students found in your class')),
      );
      return;
    }

    String selectedStudentId = students.first['_id'];
    final titleController = TextEditingController(text: 'Academic Progress & PTM Discussion');
    final agendaController = TextEditingController(text: 'Review quarterly examination marks and subject improvements.');
    DateTime meetingDate = DateTime.now().add(const Duration(days: 2));
    String timeSlot = '10:30 AM - 11:00 AM';
    String mode = 'IN_PERSON_AT_SCHOOL';
    final roomController = TextEditingController(text: 'Room 204');
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
          final currentStudent = students.firstWhere((s) => s['_id'] == selectedStudentId, orElse: () => students.first);

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
                        Text(
                          'Schedule Parent Meeting (PTM)',
                          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 20),

                    // Select Student
                    Text(
                      'Select Student / Parent',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStudentId,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          items: students.map<DropdownMenuItem<String>>((s) {
                            return DropdownMenuItem(
                              value: s['_id'],
                              child: Text(
                                '${s['name']} (#${s['rollNumber']}) - Parent: ${s['parentId']?['name'] ?? 'Not set'}',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedStudentId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: titleController,
                      label: 'Meeting Title',
                      hint: 'e.g. Quarterly Review Meeting',
                      prefixIcon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: agendaController,
                      label: 'Meeting Agenda',
                      hint: 'Key topics to discuss with the parent...',
                      prefixIcon: Icons.view_headline_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    // Date & Time Slot
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: meetingDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 60)),
                              );
                              if (picked != null) setModalState(() => meetingDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Meeting Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('yyyy-MM-dd').format(meetingDate),
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Time Slot', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(
                                  timeSlot,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Mode Selection
                    Text(
                      'Meeting Mode',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('In-Person 🏫'),
                          selected: mode == 'IN_PERSON_AT_SCHOOL',
                          onSelected: (_) => setModalState(() => mode = 'IN_PERSON_AT_SCHOOL'),
                        ),
                        ChoiceChip(
                          label: const Text('Online Meet 💻'),
                          selected: mode == 'ONLINE_MEET',
                          onSelected: (_) => setModalState(() => mode = 'ONLINE_MEET'),
                        ),
                        ChoiceChip(
                          label: const Text('Phone Call 📞'),
                          selected: mode == 'PHONE_CALL',
                          onSelected: (_) => setModalState(() => mode = 'PHONE_CALL'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: roomController,
                      label: mode == 'ONLINE_MEET' ? 'Google Meet / Zoom URL' : 'Meeting Location / Room No.',
                      hint: mode == 'ONLINE_MEET' ? 'https://meet.google.com/...' : 'Room 204, Academic Block',
                      prefixIcon: mode == 'ONLINE_MEET' ? Icons.video_call_rounded : Icons.location_on_rounded,
                    ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Schedule & Alert Parent',
                      icon: Icons.calendar_month_rounded,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final parentId = currentStudent['parentId']?['_id'];
                              if (parentId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Selected student does not have linked parent account')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final ok = await ref.read(teacherProvider.notifier).scheduleMeeting(
                                    parentId: parentId,
                                    studentId: selectedStudentId,
                                    classId: currentStudent['classId']?['_id'] ?? '',
                                    title: titleController.text.trim(),
                                    agenda: agendaController.text.trim(),
                                    meetingDate: DateFormat('yyyy-MM-dd').format(meetingDate),
                                    timeSlot: timeSlot,
                                    mode: mode,
                                    meetLinkOrRoom: roomController.text.trim(),
                                  );

                              if (ctx.mounted) Navigator.pop(ctx);

                              if (mounted) {
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.emerald,
                                      content: Text('Meeting scheduled & notification dispatched! 📅'),
                                    ),
                                  );
                                  _loadAllCommunicationData();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.rose,
                                      content: Text('Failed to schedule meeting'),
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

  // ================= Reply Inquiry Modal =================
  void _showReplyModal(Map<String, dynamic> query) {
    final replyController = TextEditingController();
    String resolutionStatus = 'RESOLVED';
    bool isSending = false;

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
                    Text(
                      'Reply to Parent Inquiry',
                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Query: "${query['message']}"',
                      style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                    ),
                    const Divider(color: AppColors.border, height: 20),

                    CustomTextField(
                      controller: replyController,
                      label: 'Teacher Response',
                      hint: 'Write clear response to address parent concern...',
                      prefixIcon: Icons.reply_rounded,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Mark Resolved ✅'),
                          selected: resolutionStatus == 'RESOLVED',
                          selectedColor: AppColors.emerald.withOpacity(0.25),
                          onSelected: (_) => setModalState(() => resolutionStatus = 'RESOLVED'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Under Review ⏳'),
                          selected: resolutionStatus == 'IN_REVIEW',
                          selectedColor: AppColors.amber.withOpacity(0.25),
                          onSelected: (_) => setModalState(() => resolutionStatus = 'IN_REVIEW'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Send Reply to Parent',
                      icon: Icons.send_rounded,
                      isLoading: isSending,
                      onPressed: isSending
                          ? null
                          : () async {
                              final text = replyController.text.trim();
                              if (text.isEmpty) return;

                              setModalState(() => isSending = true);

                              final ok = await ref.read(teacherProvider.notifier).replyToParentQuery(
                                    queryId: query['_id'],
                                    replyMessage: text,
                                    resolutionStatus: resolutionStatus,
                                  );

                              if (ctx.mounted) Navigator.pop(ctx);

                              if (mounted) {
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.emerald,
                                      content: Text('Response delivered to parent! 💬'),
                                    ),
                                  );
                                  _loadAllCommunicationData();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.rose,
                                      content: Text('Failed to send reply'),
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
  Widget build(BuildContext context) {
    final students = ref.watch(teacherProvider).students;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parent Communication Hub', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('1-on-1 Chat • Broadcasts • PTM • Inquiries', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 16), text: '1-on-1 Messages'),
            Tab(icon: Icon(Icons.campaign_rounded, size: 16), text: 'Class Notices'),
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 16), text: 'PTM Meetings'),
            Tab(icon: Icon(Icons.quiz_rounded, size: 16), text: 'Inquiries & Complaints'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 16), text: 'Progress Share'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMessagesTab(students),
                _buildAnnouncementsTab(),
                _buildMeetingsTab(),
                _buildQueriesTab(),
                _buildProgressShareTab(students),
              ],
            ),
    );
  }

  // Tab 1: 1-on-1 Parent Directory & Messaging
  Widget _buildMessagesTab(List<dynamic> students) {
    if (students.isEmpty) {
      return const Center(child: Text('No students found in assigned class', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),

      itemBuilder: (context, index) {
        final std = students[index];
        final parent = std['parentId'];

        return GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  std['name'] != null ? (std['name'] as String)[0].toUpperCase() : 'S',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      std['name'] ?? 'Student',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Parent: ${parent?['name'] ?? 'Not registered'} • #${std['rollNumber']}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (parent?['phone'] != null)
                      Text('Phone: ${parent['phone']}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showDirectMessageModal(std),
                icon: const Icon(Icons.chat_rounded, size: 14),
                label: const Text('Message', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tab 2: Class Announcements History
  Widget _buildAnnouncementsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllCommunicationData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_announcements.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No class notices published yet', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ] else ...[
            for (final ann in _announcements) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.rose.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Class Notice 📢',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.rose),
                          ),
                        ),
                        Text(
                          ann['createdAt'] != null ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(ann['createdAt'])) : '',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(ann['title'] ?? 'Notice', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(ann['message'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.done_all_rounded, size: 14, color: AppColors.emerald),
                        SizedBox(width: 4),
                        Text('Delivered to all class parents', style: TextStyle(fontSize: 11, color: AppColors.emerald)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  // Tab 3: PTM & Meetings Scheduler
  Widget _buildMeetingsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleMeetingModal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Schedule Meeting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllCommunicationData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_meetings.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No meetings scheduled yet. Tap + to schedule PTM.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ] else ...[
              for (final m in _meetings) ...[
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m['status'] ?? 'SCHEDULED',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.amber),
                            ),
                          ),
                          Text('${m['meetingDate']} • ${m['timeSlot']}',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(m['title'] ?? 'Meeting', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('With: ${m['parentId']?['name'] ?? 'Parent'} (Student: ${m['studentId']?['name'] ?? '-'})',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent)),
                      if (m['agenda'] != null && (m['agenda'] as String).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Agenda: ${m['agenda']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(m['mode'] == 'ONLINE_MEET' ? Icons.video_camera_front_rounded : Icons.location_on_rounded,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('${m['mode']?.toString().replaceAll('_', ' ')}: ${m['meetLinkOrRoom'] ?? ''}',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // Tab 4: Parent Queries & Complaints
  Widget _buildQueriesTab() {
    return RefreshIndicator(
      onRefresh: _loadAllCommunicationData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_queries.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No parent questions or complaints currently.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ] else ...[
            for (final q in _queries) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: q['resolutionStatus'] == 'RESOLVED'
                                ? AppColors.emerald.withOpacity(0.15)
                                : AppColors.rose.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            q['resolutionStatus'] ?? 'OPEN',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: q['resolutionStatus'] == 'RESOLVED' ? AppColors.emerald : AppColors.rose,
                            ),
                          ),
                        ),
                        Text('From: ${q['senderId']?['name'] ?? 'Parent'}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(q['message'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _showReplyModal(q),
                        icon: const Icon(Icons.reply_rounded, size: 14),
                        label: const Text('Reply to Parent', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  // Tab 5: Share Student Progress
  Widget _buildProgressShareTab(List<dynamic> students) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),

      itemBuilder: (context, index) {
        final std = students[index];

        return GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.emerald.withOpacity(0.2),
                child: const Icon(Icons.school_rounded, color: AppColors.emerald, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(std['name'] ?? 'Student', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('Roll No: #${std['rollNumber'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showShareProgressModal(std),
                icon: const Icon(Icons.share_rounded, size: 14),
                label: const Text('Share Progress', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
