import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class ExamManagementScreen extends ConsumerStatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  ConsumerState<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends ConsumerState<ExamManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadExamsOverview();
    });
  }

  void _showPublishDialog(BuildContext context, dynamic exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Publish Report Cards?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Verifying and publishing results for "${exam['title']}". Parents will be notified immediately and will be able to download official digital report cards.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(adminProvider.notifier).publishExamResults(
                    examTitle: exam['title'],
                    examType: exam['type'],
                  );
              if (mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report cards published & sent to parent portals!'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ref.read(adminProvider).errorMessage ?? 'Failed to publish exam results'),
                      backgroundColor: AppColors.rose,
                    ),
                  );
                }
              }
            },
            child: const Text('Publish Report Cards', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showScorecardModal(BuildContext context, dynamic scorecard) {
    final subjects = scorecard['subjects'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                      'Academic Scorecard',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    StatusBadge(status: scorecard['overallGrade'] ?? 'A', color: AppColors.emerald),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${scorecard['studentId']?['name'] ?? 'Student'} • ${scorecard['examTitle']}',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Percentage', '${scorecard['percentage']}%', AppColors.primary),
                      _buildStat('Marks', '${scorecard['totalMarksObtained']} / ${scorecard['totalMaxMarks']}', AppColors.textPrimary),
                      _buildStat('Overall Grade', scorecard['overallGrade'] ?? 'A', AppColors.emerald),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Subject-wise Breakdown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ...subjects.map((s) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s['subjectName'] ?? 'Subject', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
                        Text('${s['marksObtained']} / ${s['maxMarks']} (${s['grade']})',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final overview = adminState.examsOverview;

    final exams = overview?['exams'] as List? ?? [];
    final topRankers = overview?['topRankers'] as List? ?? [];
    final recentResults = overview?['results'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Examination & Results',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.read(adminProvider.notifier).loadExamsOverview(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(adminProvider.notifier).loadExamsOverview(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top KPI
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Active Assessment Terms',
                      value: '${exams.length}',
                      icon: Icons.assignment_rounded,
                      color: AppColors.primary,
                      subtitle: 'Weekly, Monthly, Annual',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Honor Roll Achievers',
                      value: '${topRankers.length}',
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.amber,
                      subtitle: '>= 85% Score',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Exams List & Publish Controls
              Text(
                'Examinations & Result Publishing',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              if (exams.isEmpty)
                const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No Exams Recorded',
                  message: 'Teacher marks will appear here once entered.',
                )
              else
                ...exams.map((ex) {
                  final isPub = ex['isPublished'] == true;

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex['title'] ?? 'Assessment',
                                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Type: ${ex['type']} • Avg Score: ${ex['averagePercentage']}%',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              status: isPub ? 'PUBLISHED' : 'DRAFT',
                              color: isPub ? AppColors.emerald : AppColors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${ex['totalEntries']} Scorecards Evaluated',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                            ),
                            if (!isPub)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emerald,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                                label: const Text('Verify & Publish', style: TextStyle(color: Colors.white, fontSize: 12)),
                                onPressed: () => _showPublishDialog(context, ex),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // Top Rankers Spotlight
              Text(
                'Top Academic Rankers 🏆',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              if (topRankers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'No rankers calculated yet. Teachers need to enter marks first.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                )
              else
                ...topRankers.map((r) {
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, color: AppColors.amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['studentName'] ?? 'Student',
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                '${r['className']} • ${r['examTitle']}',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${r['percentage']}%',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.emerald),
                            ),
                            Text(
                              'Grade ${r['overallGrade']}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // Recent Scorecards
              if (recentResults.isNotEmpty) ...[
                Text(
                  'Recent Scorecards',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ...recentResults.take(5).map((sc) {
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sc['studentId']?['name'] ?? 'Student',
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                '${sc['examTitle']} • Grade ${sc['overallGrade']}',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showScorecardModal(context, sc),
                          child: const Text('View Card', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
