import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/teacher_provider.dart';

class TeacherScheduleScreen extends ConsumerStatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  ConsumerState<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends ConsumerState<TeacherScheduleScreen> {
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  late String _selectedDay;

  @override
  void initState() {
    super.initState();
    // Default to current day if weekday, or Monday if Sunday
    final today = DateFormat('EEEE').format(DateTime.now());
    _selectedDay = _days.contains(today) ? today : 'Monday';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teacherProvider.notifier).loadTeachingSchedule();
    });
  }

  String _getPeriodLiveStatus(String? startTimeStr, String? endTimeStr, String periodDay) {
    final now = DateTime.now();
    final todayName = DateFormat('EEEE').format(now);

    if (periodDay != todayName) {
      return '';
    }

    if (startTimeStr == null || endTimeStr == null) return '';

    try {
      final timeFormat = DateFormat('hh:mm a');
      final startDt = timeFormat.parse(startTimeStr.trim());
      final endDt = timeFormat.parse(endTimeStr.trim());

      final startToday = DateTime(now.year, now.month, now.day, startDt.hour, startDt.minute);
      final endToday = DateTime(now.year, now.month, now.day, endDt.hour, endDt.minute);

      if (now.isAfter(startToday) && now.isBefore(endToday)) {
        return 'ONGOING';
      } else if (now.isBefore(startToday)) {
        return 'UPCOMING';
      } else {
        return 'COMPLETED';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherProvider);
    final scheduleData = teacherState.teachingSchedule;
    final weeklySchedule = (scheduleData?['weeklySchedule'] as Map<String, dynamic>?) ?? {};
    final assignedClasses = (scheduleData?['assignedClasses'] as List<dynamic>?) ?? [];
    final assignedSubjects = (scheduleData?['assignedSubjects'] as List<dynamic>?) ?? [];
    final summary = (scheduleData?['summary'] as Map<String, dynamic>?) ?? {};
    final totalWeeklyPeriods = summary['totalWeeklyPeriods'] ?? 0;
    final todayDayName = scheduleData?['todayDay'] ?? DateFormat('EEEE').format(DateTime.now());

    final periodsForSelectedDay = (weeklySchedule[_selectedDay] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Teaching Timetable',
          style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Schedule',
            onPressed: () => ref.read(teacherProvider.notifier).loadTeachingSchedule(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(teacherProvider.notifier).loadTeachingSchedule(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Institutional Overview Card
              GlassCard(
                padding: const EdgeInsets.all(18),
                gradient: AppColors.cardGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned Academic Schedule',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Allocated by School Admin & Super Admin',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.emerald, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 14),

                    // Metrics Strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('Weekly Periods', '$totalWeeklyPeriods', Icons.access_time_filled_rounded, AppColors.primary),
                        Container(width: 1, height: 32, color: AppColors.border),
                        _buildMetricCol('Classes', '${assignedClasses.length}', Icons.meeting_room_rounded, AppColors.accent),
                        Container(width: 1, height: 32, color: AppColors.border),
                        _buildMetricCol('Subjects', '${assignedSubjects.length}', Icons.menu_book_rounded, AppColors.amber),
                      ],
                    ),

                    if (assignedSubjects.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: assignedSubjects.map((sub) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  sub.toString(),
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Day Selector Horizontal Bar
              Text(
                'Weekly Teaching Days',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _days.map((day) {
                    final isSelected = day == _selectedDay;
                    final isToday = day == todayDayName;
                    final periodCount = (weeklySchedule[day] as List<dynamic>?)?.length ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDay = day),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.primaryGradient : null,
                            color: isSelected ? null : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : isToday
                                      ? AppColors.emerald.withOpacity(0.5)
                                      : AppColors.border,
                              width: isToday ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                day.substring(0, 3),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.emerald,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$periodCount',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Selected Day Header & Periods List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_selectedDay Schedule',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${periodsForSelectedDay.length} Periods Scheduled',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (teacherState.isLoadingSchedule && periodsForSelectedDay.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (periodsForSelectedDay.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  child: EmptyState(
                    icon: Icons.free_cancellation_rounded,
                    title: 'No Classes on $_selectedDay',
                    message: 'You have no teaching periods scheduled on this day.',
                  ),
                )
              else
                ...periodsForSelectedDay.map((p) {
                  final periodNumber = p['periodNumber'] ?? 1;
                  final subject = p['subject'] ?? 'Subject';
                  final startTime = p['startTime'] ?? '--:--';
                  final endTime = p['endTime'] ?? '--:--';
                  final className = p['classDisplayName'] ?? '${p['className']} - ${p['section']}';
                  final room = p['roomNumber'] ?? 'Classroom';
                  final isClassTeacher = p['isClassTeacher'] == true;
                  final status = _getPeriodLiveStatus(startTime, endTime, _selectedDay);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Period Number Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Period $periodNumber',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Time Slot Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$startTime - $endTime',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              // Live Status Indicator
                              if (status == 'ONGOING')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.emerald),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.emerald,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'LIVE NOW',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (status == 'UPCOMING')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'UPCOMING',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                )
                              else if (status == 'COMPLETED')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'COMPLETED',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Subject & Classroom Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.auto_stories_rounded, color: AppColors.accent, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.school_rounded, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          className,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(Icons.room_rounded, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 2),
                                        Text(
                                          room,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isClassTeacher)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Class Teacher',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.purple),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // Assigned Classes Breakdown Section
              Text(
                'My Assigned Classes & Rooms',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              if (assignedClasses.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No assigned classes found. Please contact your school administrator.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                )
              else
                ...assignedClasses.map((cls) {
                  final name = cls['displayName'] ?? '${cls['name']} - ${cls['section']}';
                  final room = cls['roomNumber'] ?? 'Standard Room';
                  final subs = (cls['subjects'] as List<dynamic>?) ?? [];
                  final isCt = cls['isClassTeacher'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.class_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (isCt) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.emerald.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Class Teacher',
                                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.emerald, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$room • Teaching: ${subs.join(", ")}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

