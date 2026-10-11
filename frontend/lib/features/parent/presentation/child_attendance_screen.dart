import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../teacher/presentation/attendance_report_screen.dart';
import '../providers/parent_provider.dart';

class ChildAttendanceScreen extends ConsumerWidget {
  const ChildAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentState = ref.watch(parentProvider);
    final child = parentState.currentChild;
    final childDashboard = parentState.childDashboard;

    final todayAttendance = childDashboard?['todayAttendance'] ?? 'NOT_YET_MARKED';
    final studentId = child?['_id'];
    final studentName = child?['name'] ?? 'Your Child';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$studentName - Attendance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's Live Status Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              gradient: AppColors.cardGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today’s Real-Time Status',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Live Sync ⚡',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: todayAttendance == 'PRESENT'
                              ? AppColors.emerald.withOpacity(0.2)
                              : todayAttendance == 'ABSENT'
                                  ? AppColors.rose.withOpacity(0.2)
                                  : AppColors.amber.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          todayAttendance == 'PRESENT'
                              ? Icons.check_circle_rounded
                              : todayAttendance == 'ABSENT'
                                  ? Icons.cancel_rounded
                                  : Icons.access_time_rounded,
                          size: 32,
                          color: todayAttendance == 'PRESENT'
                              ? AppColors.emerald
                              : todayAttendance == 'ABSENT'
                                  ? AppColors.rose
                                  : AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todayAttendance == 'PRESENT'
                                ? 'Marked Present'
                                : todayAttendance == 'ABSENT'
                                    ? 'Marked Absent'
                                    : 'Awaiting Class Roll Call',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Class Teacher updates roll call daily',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Instant Alert Guarantee Callout
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, size: 24, color: AppColors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'As soon as the class teacher marks daily attendance, you receive an instant push notification on your phone.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Embedded Monthly Calendar
            Text(
              'Monthly Detailed Attendance Breakdown',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (studentId != null)
              SizedBox(
                height: 500,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AttendanceReportScreen(
                    studentId: studentId,
                    studentName: studentName,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
