import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/parent_provider.dart';

class HolidayCalendarScreen extends ConsumerWidget {
  const HolidayCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidays = ref.watch(parentProvider).holidays;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('School Holiday Calendar'),
      ),
      body: holidays.isEmpty
          ? const EmptyState(
              icon: Icons.beach_access_rounded,
              title: 'No Upcoming Holidays',
              description: 'The school holiday calendar has not been published yet.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: holidays.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final h = holidays[index];
                final sDate = h['startDate'] != null
                    ? DateFormat('MMM d, yyyy').format(DateTime.parse(h['startDate']))
                    : '';
                final eDate = h['endDate'] != null
                    ? DateFormat('MMM d, yyyy').format(DateTime.parse(h['endDate']))
                    : '';

                final isSameDay = sDate == eDate;

                return GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.celebration_rounded, color: AppColors.amber, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h['title'] ?? 'Holiday',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSameDay ? sDate : '$sDate — $eDate',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                            if (h['description'] != null && h['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                h['description'],
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
