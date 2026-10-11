import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class UserApprovalsScreen extends ConsumerWidget {
  const UserApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final pendingUsers = adminState.pendingApprovals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending User Approvals'),
      ),
      body: pendingUsers.isEmpty
          ? const EmptyState(
              icon: Icons.verified_user_rounded,
              title: 'All Clear!',
              description: 'There are no pending registrations waiting for administrative approval.',
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(adminProvider.notifier).loadDashboard(),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pendingUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final user = pendingUsers[index];
                  final isTeacher = user['role'] == 'TEACHER';
                  final subjects = user['subjects'] as List<dynamic>? ?? [];

                  return GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isTeacher
                                  ? AppColors.emerald.withOpacity(0.2)
                                  : AppColors.accent.withOpacity(0.2),
                              child: Text(
                                user['name'] != null && user['name'].toString().isNotEmpty
                                    ? user['name'][0].toUpperCase()
                                    : 'U',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isTeacher ? AppColors.emerald : AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'Unknown User',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user['email'] ?? user['phone'] ?? 'No contact info',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: user['role'] ?? 'USER'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 14),

                        if (isTeacher) ...[
                          if (subjects.isNotEmpty) ...[
                            Text(
                              'Subjects Taught:',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: subjects.map((sub) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    sub.toString(),
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (user['qualification'] != null && user['qualification'].toString().isNotEmpty)
                            Text(
                              'Qualification: ${user['qualification']}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                        ] else ...[
                          if (user['address'] != null && user['address'].toString().isNotEmpty)
                            Text(
                              'Residential Address: ${user['address']}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                        ],

                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Approve',
                                icon: Icons.check_circle_rounded,
                                color: AppColors.emerald,
                                height: 44,
                                onPressed: () async {
                                  final ok = await ref
                                      .read(adminProvider.notifier)
                                      .updateApprovalStatus(user['_id'], 'APPROVED');
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.emerald,
                                        content: Text('${user['name']} has been approved!'),
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
                                height: 44,
                                onPressed: () async {
                                  final ok = await ref
                                      .read(adminProvider.notifier)
                                      .updateApprovalStatus(user['_id'], 'REJECTED');
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.rose,
                                        content: Text('${user['name']} has been rejected.'),
                                      ),
                                    );
                                  }
                                },
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
