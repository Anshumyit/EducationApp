import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/teacher_provider.dart';

class LeaveApprovalScreen extends ConsumerWidget {
  const LeaveApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherProvider);
    final leaves = teacherState.leaveRequests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Leave Requests'),
      ),
      body: leaves.isEmpty
          ? const EmptyState(
              icon: Icons.beach_access_rounded,
              title: 'No Leave Requests',
              description: 'There are no pending student leave applications for your class.',
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(teacherProvider.notifier).loadDashboard(),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: leaves.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final leave = leaves[index];
                  final student = leave['studentId'] is Map ? leave['studentId'] : null;
                  final parent = leave['parentId'] is Map ? leave['parentId'] : null;
                  final status = leave['status'] ?? 'PENDING';
                  final isPending = status == 'PENDING';

                  final startDate = leave['startDate'] != null
                      ? DateFormat('MMM d, yyyy').format(DateTime.parse(leave['startDate']))
                      : '';
                  final endDate = leave['endDate'] != null
                      ? DateFormat('MMM d, yyyy').format(DateTime.parse(leave['endDate']))
                      : '';

                  return GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primary.withOpacity(0.2),
                                  child: Text(
                                    student != null && student['name'] != null
                                        ? student['name'][0].toUpperCase()
                                        : 'S',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student?['name'] ?? 'Student',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Parent: ${parent?['name'] ?? 'Guardian'}',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            StatusBadge(status: status),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 14),

                        // Date Duration
                        Row(
                          children: [
                            const Icon(Icons.date_range_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Duration: $startDate — $endDate',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Reason
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Reason: ${leave['reason'] ?? 'No reason specified'}',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ),

                        if (isPending) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Approve Leave',
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.emerald,
                                  height: 42,
                                  onPressed: () async {
                                    final ok = await ref.read(teacherProvider.notifier).reviewLeave(
                                          leaveId: leave['_id'],
                                          status: 'APPROVED',
                                          reviewNotes: 'Approved by class teacher',
                                        );
                                    if (context.mounted && ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: AppColors.emerald,
                                          content: Text('Leave request approved & parent notified!'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomButton(
                                  text: 'Reject',
                                  icon: Icons.cancel_rounded,
                                  color: AppColors.rose,
                                  isOutlined: true,
                                  height: 42,
                                  onPressed: () async {
                                    final ok = await ref.read(teacherProvider.notifier).reviewLeave(
                                          leaveId: leave['_id'],
                                          status: 'REJECTED',
                                          reviewNotes: 'Unable to approve due to academic schedule',
                                        );
                                    if (context.mounted && ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: AppColors.rose,
                                          content: Text('Leave request rejected.'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
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
