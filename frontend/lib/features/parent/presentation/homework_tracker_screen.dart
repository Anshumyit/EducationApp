import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/parent_provider.dart';

class HomeworkTrackerScreen extends ConsumerWidget {
  const HomeworkTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentState = ref.watch(parentProvider);
    final homeworks = parentState.homeworkList;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Homework & Assignments'),
      ),
      body: homeworks.isEmpty
          ? const EmptyState(
              icon: Icons.assignment_turned_in_rounded,
              title: 'No Active Assignments',
              description: 'Your child does not have any pending homework assignments.',
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(parentProvider.notifier).loadDashboard(),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: homeworks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final hw = homeworks[index];
                  final subject = hw['subject'] ?? 'General';
                  final title = hw['title'] ?? 'Homework';
                  final description = hw['description'] ?? '';

                  final assignedDate = hw['assignedDate'] != null
                      ? DateFormat('MMM d, yyyy').format(DateTime.parse(hw['assignedDate']))
                      : '';
                  final submissionDate = hw['submissionDate'] != null
                      ? DateFormat('MMM d, yyyy').format(DateTime.parse(hw['submissionDate']))
                      : '';

                  return GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                subject,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: AppColors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  'Due: $submissionDate',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 14),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Assigned: $assignedDate',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Tracked Online',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald,
                                ),
                              ),
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
