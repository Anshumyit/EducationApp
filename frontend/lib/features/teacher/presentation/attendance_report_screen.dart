import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';

class AttendanceReportScreen extends StatefulWidget {
  final String? studentId;
  final String? studentName;

  const AttendanceReportScreen({super.key, this.studentId, this.studentName});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  String _selectedMonth = '10';
  String _selectedYear = '2026';

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final id = widget.studentId ?? '67073bf7c20c904fa3a02bb1';
      final res = await DioClient.instance.get(
        '${ApiConstants.studentAttendanceReport}/$id/report',
        queryParameters: {'month': _selectedMonth, 'year': _selectedYear},
      );
      setState(() {
        _reportData = res.data['data'];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _reportData?['summary'];
    final dailyHistory = _reportData?['dailyHistory'] as List<dynamic>? ?? [];
    final percentage = summary?['percentage'] ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.studentName != null ? '${widget.studentName} Attendance' : 'Monthly Attendance Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Month / Year Selector
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reporting Period: October 2026',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$percentage% Attendance',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: percentage >= 75 ? AppColors.emerald : AppColors.rose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary metrics
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Present Days',
                          value: '${summary?['present'] ?? 0}',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Absent Days',
                          value: '${summary?['absent'] ?? 0}',
                          icon: Icons.cancel_rounded,
                          color: AppColors.rose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Late Days',
                          value: '${summary?['late'] ?? 0}',
                          icon: Icons.access_time_filled_rounded,
                          color: AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Total Days',
                          value: '${summary?['totalWorkingDays'] ?? 0}',
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Daily Attendance Log',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (dailyHistory.isEmpty)
                    const EmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'No Logs Found',
                      description: 'No daily attendance records have been registered for this month.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dailyHistory.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final log = dailyHistory[index];
                        final status = log['status'] ?? 'PRESENT';

                        return GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.event_note_rounded, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 10),
                                  Text(
                                    log['date'] ?? '',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              StatusBadge(status: status),
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
