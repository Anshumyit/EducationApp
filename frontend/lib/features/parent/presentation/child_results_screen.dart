import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/parent_provider.dart';

class ChildResultsScreen extends ConsumerStatefulWidget {
  const ChildResultsScreen({super.key});

  @override
  ConsumerState<ChildResultsScreen> createState() => _ChildResultsScreenState();
}

class _ChildResultsScreenState extends ConsumerState<ChildResultsScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'WEEKLY', 'MONTHLY', 'HALF_YEARLY', 'ANNUAL'

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentProvider);
    final allResults = parentState.examResults;
    final child = parentState.currentChild;
    final childName = child?['name'] ?? 'Child';

    final filteredResults = _selectedFilter == 'ALL'
        ? allResults
        : allResults.where((r) => r['examType'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$childName Academic Results'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab('ALL', 'All Tests'),
                  const SizedBox(width: 8),
                  _buildFilterTab('WEEKLY', 'Weekly Tests'),
                  const SizedBox(width: 8),
                  _buildFilterTab('MONTHLY', 'Monthly Exams'),
                  const SizedBox(width: 8),
                  _buildFilterTab('HALF_YEARLY', '6 Months (Mid-Term)'),
                  const SizedBox(width: 8),
                  _buildFilterTab('ANNUAL', '1 Year (Annual Final)'),
                ],
              ),
            ),
          ),

          // Results List
          Expanded(
            child: filteredResults.isEmpty
                ? const EmptyState(
                    icon: Icons.grade_outlined,
                    title: 'No Exam Results Published',
                    description: 'Results for the selected exam category have not been recorded yet.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final res = filteredResults[index];
                      final subjects = res['subjects'] as List<dynamic>? ?? [];
                      final percentage = res['percentage'] ?? 0;
                      final grade = res['overallGrade'] ?? 'A';
                      final examTitle = res['examTitle'] ?? 'Examination';
                      final examType = res['examType'] ?? 'EXAM';

                      return GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        examTitle,
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Academic Session: ${res['academicYear'] ?? '2026-2027'}',
                                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(status: examType),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: AppColors.border, height: 1),
                            const SizedBox(height: 16),

                            // Score & Grade banner
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text('Total Score', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${res['totalMarksObtained']} / ${res['totalMaxMarks']}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 30, color: AppColors.border),
                                  Column(
                                    children: [
                                      Text('Percentage', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$percentage%',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 30, color: AppColors.border),
                                  Column(
                                    children: [
                                      Text('Grade', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                      const SizedBox(height: 2),
                                      Text(
                                        grade,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Subject Breakdown
                            Text(
                              'Subject Scorecard:',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),

                            ...subjects.map((sub) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      sub['subjectName'] ?? '',
                                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      '${sub['marksObtained']} / ${sub['maxMarks']}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.emerald,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
