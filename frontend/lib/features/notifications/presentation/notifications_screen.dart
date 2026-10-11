import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'ATTENDANCE':
        return Icons.how_to_reg_rounded;
      case 'HOMEWORK':
        return Icons.menu_book_rounded;
      case 'RESULT':
        return Icons.grade_rounded;
      case 'LEAVE':
        return Icons.beach_access_rounded;
      case 'FEE':
        return Icons.payments_rounded;
      case 'BROADCAST':
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'ATTENDANCE':
        return AppColors.emerald;
      case 'HOMEWORK':
        return AppColors.purple;
      case 'RESULT':
        return AppColors.accent;
      case 'LEAVE':
        return AppColors.amber;
      case 'FEE':
        return AppColors.rose;
      case 'BROADCAST':
      default:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final notifications = notifState.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications & Alerts Feed'),
      ),
      body: notifState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No Notifications Yet',
                  description: 'All your academic alerts, attendance notifications, and announcements will appear here.',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final isRead = n['isRead'] == true;
                      final type = n['type'];
                      final color = _getColorForType(type);
                      final icon = _getIconForType(type);

                      final timeStr = n['createdAt'] != null
                          ? DateFormat('MMM d, h:mm a').format(DateTime.parse(n['createdAt']))
                          : 'Just now';

                      return GlassCard(
                        onTap: () {
                          if (!isRead) {
                            ref.read(notificationProvider.notifier).markAsRead(n['_id']);
                          }
                        },
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n['title'] ?? 'Notice',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(left: 6),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryLight,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n['message'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    timeStr,
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
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
