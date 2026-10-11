import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/teacher_provider.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _attendanceMap = {}; // studentId -> 'PRESENT' | 'ABSENT' | 'LATE'
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final students = ref.read(teacherProvider).students;
    for (final s in students) {
      _attendanceMap[s['_id']] = 'PRESENT';
    }
  }

  void _markAll(String status) {
    setState(() {
      final students = ref.read(teacherProvider).students;
      for (final s in students) {
        _attendanceMap[s['_id']] = status;
      }
    });
  }

  Future<void> _submitAttendance() async {
    final teacherState = ref.read(teacherProvider);
    final classId = teacherState.classInfo?['classroom']?['_id'];

    if (classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assigned class found to mark attendance')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final records = _attendanceMap.entries.map((e) {
      return {
        'studentId': e.key,
        'status': e.value,
        'remarks': '',
      };
    }).toList();

    final ok = await ref.read(teacherProvider.notifier).markAttendance(
          classId: classId,
          date: dateStr,
          records: records,
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Attendance saved & real-time alerts sent to parents! 🔔'),
        ),
      );
      Navigator.pop(context);
    } else {
      final err = ref.read(teacherProvider).errorMessage ?? 'Failed to submit attendance';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.rose, content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(teacherProvider).students;
    final dateDisplay = DateFormat('EEEE, MMM d, yyyy').format(_selectedDate);

    int presentCount = _attendanceMap.values.where((v) => v == 'PRESENT').length;
    int absentCount = _attendanceMap.values.where((v) => v == 'ABSENT').length;
    int lateCount = _attendanceMap.values.where((v) => v == 'LATE').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Attendance'),
      ),
      body: Column(
        children: [
          // Header / Date bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryLight),
                    const SizedBox(width: 8),
                    Text(
                      dateDisplay,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _markAll('PRESENT'),
                  icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.emerald),
                  label: Text(
                    'All Present',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Summary Chip Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: AppColors.surfaceLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill('Present', presentCount, AppColors.emerald),
                _buildStatPill('Absent', absentCount, AppColors.rose),
                _buildStatPill('Late', lateCount, AppColors.amber),
              ],
            ),
          ),

          // Student Attendance List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = students[index];
                final studentId = student['_id'];
                final currentStatus = _attendanceMap[studentId] ?? 'PRESENT';

                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Roll badge
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surface,
                        child: Text(
                          '${student['rollNumber'] ?? index + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name
                      Expanded(
                        child: Text(
                          student['name'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      // Status Toggle Chips
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildChoiceChip(
                            label: 'P',
                            selected: currentStatus == 'PRESENT',
                            activeColor: AppColors.emerald,
                            onTap: () => setState(() => _attendanceMap[studentId] = 'PRESENT'),
                          ),
                          const SizedBox(width: 6),
                          _buildChoiceChip(
                            label: 'A',
                            selected: currentStatus == 'ABSENT',
                            activeColor: AppColors.rose,
                            onTap: () => setState(() => _attendanceMap[studentId] = 'ABSENT'),
                          ),
                          const SizedBox(width: 6),
                          _buildChoiceChip(
                            label: 'L',
                            selected: currentStatus == 'LATE',
                            activeColor: AppColors.amber,
                            onTap: () => setState(() => _attendanceMap[studentId] = 'LATE'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Submit Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: CustomButton(
              text: 'Save Attendance & Notify Parents',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitAttendance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
