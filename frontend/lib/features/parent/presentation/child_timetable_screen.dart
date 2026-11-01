import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/parent_provider.dart';

class ChildTimetableScreen extends ConsumerStatefulWidget {
  final dynamic child;

  const ChildTimetableScreen({super.key, required this.child});

  @override
  ConsumerState<ChildTimetableScreen> createState() => _ChildTimetableScreenState();
}

class _ChildTimetableScreenState extends ConsumerState<ChildTimetableScreen> {
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  late String _selectedDay;

  bool _isLoading = true;
  Map<String, dynamic>? _classroomData;
  Map<String, List<Map<String, dynamic>>> _timetableByDay = {};

  @override
  void initState() {
    super.initState();
    final today = DateFormat('EEEE').format(DateTime.now());
    _selectedDay = _days.contains(today) ? today : 'Monday';

    _initDays();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimetable();
    });
  }

  void _initDays() {
    _timetableByDay = {};
    for (final day in _days) {
      _timetableByDay[day] = [];
    }
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    final studentId = widget.child['_id'];
    final data = await ref.read(parentProvider.notifier).fetchChildTimetable(studentId);

    if (mounted) {
      if (data != null) {
        _classroomData = data['classroom'];
        final timetableList = (data['timetable'] as List<dynamic>?) ?? [];

        _initDays();
        for (final item in timetableList) {
          final day = item['day']?.toString();
          if (day != null && _timetableByDay.containsKey(day)) {
            final periods = (item['periods'] as List<dynamic>?) ?? [];
            final list = periods.map((p) => Map<String, dynamic>.from(p)).toList();
            list.sort((a, b) => (a['periodNumber'] ?? 0).compareTo(b['periodNumber'] ?? 0));
            _timetableByDay[day] = list;
          }
        }
      }
      setState(() => _isLoading = false);
    }
  }

  String _getPeriodLiveStatus(String? startTimeStr, String? endTimeStr, String periodDay) {
    final now = DateTime.now();
    final todayName = DateFormat('EEEE').format(now);

    if (periodDay != todayName) return '';
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

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return const Color(0xFF6366F1);
    if (s.contains('physic') || s.contains('sci')) return const Color(0xFF06B6D4);
    if (s.contains('chem')) return const Color(0xFFEC4899);
    if (s.contains('bio')) return const Color(0xFF10B981);
    if (s.contains('eng')) return const Color(0xFFF59E0B);
    if (s.contains('hist') || s.contains('soc')) return const Color(0xFF8B5CF6);
    if (s.contains('comp') || s.contains('it')) return const Color(0xFF3B82F6);
    if (s.contains('art') || s.contains('draw')) return const Color(0xFFF43F5E);
    if (s.contains('sport') || s.contains('pe') || s.contains('phys')) return const Color(0xFF14B8A6);
    return AppColors.primary;
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return Icons.calculate_rounded;
    if (s.contains('physic') || s.contains('sci')) return Icons.science_rounded;
    if (s.contains('chem')) return Icons.biotech_rounded;
    if (s.contains('bio')) return Icons.nature_people_rounded;
    if (s.contains('eng')) return Icons.menu_book_rounded;
    if (s.contains('hist') || s.contains('soc')) return Icons.public_rounded;
    if (s.contains('comp') || s.contains('it')) return Icons.computer_rounded;
    if (s.contains('art')) return Icons.palette_rounded;
    if (s.contains('sport') || s.contains('pe')) return Icons.sports_soccer_rounded;
    return Icons.auto_stories_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final childName = child['name'] ?? 'Child';
    final rollNumber = child['rollNumber'] ?? '1';

    final className = _classroomData != null
        ? '${_classroomData!['name']} - ${_classroomData!['section']}'
        : (child['classId'] is Map
            ? '${child['classId']['name']} - ${child['classId']['section']}'
            : 'Class');

    final classTeacher = _classroomData != null && _classroomData!['classTeacher'] is Map
        ? _classroomData!['classTeacher']['name']
        : (child['classId'] is Map && child['classId']['classTeacher'] is Map
            ? child['classId']['classTeacher']['name']
            : 'Unassigned');

    final roomNumber = _classroomData?['roomNumber'] ?? (child['classId'] is Map ? child['classId']['roomNumber'] : null) ?? 'Room A-101';

    final periodsForSelectedDay = _timetableByDay[_selectedDay] ?? [];
    final todayName = DateFormat('EEEE').format(DateTime.now());
    final isSelectedDayToday = _selectedDay == todayName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$childName\'s Timetable',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '$className • Routine & Periods',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Routine',
            onPressed: _loadTimetable,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTimetable,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Overview Card
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      gradient: AppColors.cardGradient,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      className,
                                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        'Roll #$rollNumber',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Class Teacher: $classTeacher',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Assigned Room: $roomNumber',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Day Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _days.map((day) {
                          final isSelected = day == _selectedDay;
                          final isToday = day == todayName;
                          final periodCount = (_timetableByDay[day] ?? []).length;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedDay = day),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isToday ? AppColors.primary.withOpacity(0.12) : AppColors.surface),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isToday ? AppColors.primary.withOpacity(0.5) : AppColors.border),
                                    width: isSelected || isToday ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      day.substring(0, 3),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : (isToday ? AppColors.primary : AppColors.textPrimary),
                                      ),
                                    ),
                                    if (periodCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$periodCount',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Day Header & Count Banner
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$_selectedDay Schedule',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (isSelectedDayToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'TODAY',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${periodsForSelectedDay.length} Periods',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Schedule Period Cards
                    if (periodsForSelectedDay.isEmpty)
                      EmptyState(
                        icon: Icons.event_busy_rounded,
                        title: 'No Classes on $_selectedDay',
                        description: 'No lectures or periods scheduled for $className on this day.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: periodsForSelectedDay.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final period = periodsForSelectedDay[index];
                          final periodNum = period['periodNumber'] ?? (index + 1);
                          final subject = period['subject'] ?? 'General';
                          final startTime = period['startTime'] ?? '08:30 AM';
                          final endTime = period['endTime'] ?? '09:15 AM';
                          final teacherName = period['teacher'] is Map
                              ? (period['teacher']['name'] ?? 'Faculty')
                              : (period['teacherName'] ?? 'Assigned Faculty');
                          final periodRoom = period['roomNumber'] ?? roomNumber;

                          final liveStatus = _getPeriodLiveStatus(startTime, endTime, _selectedDay);
                          final subjectColor = _getSubjectColor(subject);
                          final subjectIcon = _getSubjectIcon(subject);

                          return GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Period Number Column
                                Container(
                                  width: 44,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: subjectColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: subjectColor.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'P$periodNum',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: subjectColor,
                                        ),
                                      ),
                                      Icon(subjectIcon, size: 14, color: subjectColor),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 14),

                                // Subject & Teacher details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subject,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (liveStatus.isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: liveStatus == 'ONGOING'
                                                    ? AppColors.emerald.withOpacity(0.15)
                                                    : liveStatus == 'UPCOMING'
                                                        ? AppColors.primary.withOpacity(0.15)
                                                        : AppColors.surface,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (liveStatus == 'ONGOING')
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      margin: const EdgeInsets.only(right: 4),
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.emerald,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  Text(
                                                    liveStatus,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: liveStatus == 'ONGOING'
                                                          ? AppColors.emerald
                                                          : liveStatus == 'UPCOMING'
                                                              ? AppColors.primaryLight
                                                              : AppColors.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              teacherName,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.meeting_room_outlined, size: 13, color: AppColors.textMuted),
                                          const SizedBox(width: 3),
                                          Text(
                                            periodRoom,
                                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Timing slot
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        startTime,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                      Text(
                                        endTime,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
