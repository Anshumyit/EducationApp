import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class UserApprovalsScreen extends ConsumerStatefulWidget {
  const UserApprovalsScreen({super.key});

  @override
  ConsumerState<UserApprovalsScreen> createState() => _UserApprovalsScreenState();
}

class _UserApprovalsScreenState extends ConsumerState<UserApprovalsScreen> {
  final Set<String> _processingUserIds = {};

  @override
  void initState() {
    super.initState();
    // Automatically load latest pending registrations whenever this screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadPendingApprovals();
    });
  }

  Future<void> _handleApproval(dynamic user, String status) async {
    final userId = user['_id']?.toString() ?? '';
    if (userId.isEmpty || _processingUserIds.contains(userId)) return;

    setState(() {
      _processingUserIds.add(userId);
    });

    final userName = user['name'] ?? 'User';
    final isApproved = status == 'APPROVED';

    final success = await ref
        .read(adminProvider.notifier)
        .updateApprovalStatus(userId, status);

    if (!mounted) return;

    setState(() {
      _processingUserIds.remove(userId);
    });

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isApproved ? AppColors.emerald : AppColors.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Icon(
                isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isApproved
                      ? '$userName has been approved! Account is now active.'
                      : '$userName registration has been rejected.',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final error = ref.read(adminProvider).errorMessage;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(error ?? 'Failed to update user status'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              onRefresh: () => ref.read(adminProvider.notifier).loadPendingApprovals(),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pendingUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final user = pendingUsers[index];
                  final userId = user['_id']?.toString() ?? '';
                  final isTeacher = user['role'] == 'TEACHER';
                  final subjects = user['subjects'] as List<dynamic>? ?? [];
                  final isBusy = _processingUserIds.contains(userId);

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
                                isLoading: isBusy,
                                onPressed: isBusy ? null : () => _handleApproval(user, 'APPROVED'),
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
                                onPressed: isBusy ? null : () => _handleApproval(user, 'REJECTED'),
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
