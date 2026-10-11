import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/parent_provider.dart';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  final _reasonController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  bool _isSubmitting = false;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reason for leave')),
      );
      return;
    }

    final currentChild = ref.read(parentProvider).currentChild;
    if (currentChild == null) return;

    setState(() => _isSubmitting = true);

    final ok = await ref.read(parentProvider.notifier).submitLeaveRequest(
          studentId: currentChild['_id'],
          startDate: _startDate,
          endDate: _endDate,
          reason: reason,
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ok) {
      _reasonController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Leave application sent to Class Teacher successfully! 📝'),
        ),
      );
    } else {
      final err = ref.read(parentProvider).errorMessage ?? 'Failed to submit leave';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.rose, content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentProvider);
    final myLeaves = parentState.myLeaves;
    final child = parentState.currentChild;
    final childName = child?['name'] ?? 'Your Child';

    final rangeText = '${DateFormat('MMM d').format(_startDate)} — ${DateFormat('MMM d, yyyy').format(_endDate)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Apply Leave for $childName'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Application Form
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Leave Request',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Application is forwarded directly to the class teacher for review.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Date range selector
                  Text(
                    'Leave Period',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.accent),
                              const SizedBox(width: 10),
                              Text(rangeText, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  CustomTextField(
                    controller: _reasonController,
                    label: 'Reason for Absence',
                    hint: 'e.g. Attending family function, medical appointment...',
                    prefixIcon: Icons.edit_note_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Send Request to Class Teacher',
                    icon: Icons.send_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _handleSubmit,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Leave History
            Text(
              'Past Applications & Approvals',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            if (myLeaves.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No past leave applications on record.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myLeaves.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final leave = myLeaves[index];
                  final sDate = leave['startDate'] != null
                      ? DateFormat('MMM d').format(DateTime.parse(leave['startDate']))
                      : '';
                  final eDate = leave['endDate'] != null
                      ? DateFormat('MMM d, yyyy').format(DateTime.parse(leave['endDate']))
                      : '';

                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$sDate — $eDate',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            StatusBadge(status: leave['status'] ?? 'PENDING'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Reason: ${leave['reason'] ?? ''}',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        if (leave['reviewNotes'] != null && leave['reviewNotes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Teacher Note: ${leave['reviewNotes']}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
