import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/teacher_provider.dart';
import 'attendance_report_screen.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const MarkAttendanceScreen({super.key, this.initialDate});

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  late DateTime _selectedDate;
  final Map<String, String> _attendanceMap = {}; // studentId -> 'PRESENT' | 'ABSENT' | 'LATE'
  bool _isLoadingDate = false;
  bool _isAlreadyMarked = false;
  bool _isSubmitting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();

    // Default init from students
    final students = ref.read(teacherProvider).students;
    for (final s in students) {
      _attendanceMap[s['_id']] = 'PRESENT';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceForDate(_selectedDate);
    });
  }

  Future<void> _loadAttendanceForDate(DateTime date) async {
    final teacherState = ref.read(teacherProvider);
    final classId = teacherState.classInfo?['classroom']?['_id'];
    if (classId == null) return;

    setState(() => _isLoadingDate = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final data = await ref.read(teacherProvider.notifier).fetchAttendanceForDate(
          classId: classId,
          date: dateStr,
        );

    final students = ref.read(teacherProvider).students;
    final records = data?['records'] as List<dynamic>?;

    setState(() {
      _isLoadingDate = false;
      if (records != null && records.isNotEmpty) {
        _isAlreadyMarked = true;
        for (final rec in records) {
          final sId = rec['studentId'] is Map ? rec['studentId']['_id'] : rec['studentId'];
          if (sId != null && rec['status'] != null) {
            _attendanceMap[sId.toString()] = rec['status'].toString();
          }
        }
      } else {
        _isAlreadyMarked = false;
        // Default everyone to PRESENT if not yet marked
        for (final s in students) {
          _attendanceMap[s['_id']] ??= 'PRESENT';
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAttendanceForDate(picked);
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
      setState(() => _isAlreadyMarked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Attendance recorded for $dateStr! Parents notified in real time 🔔'),
          action: SnackBarAction(
            label: 'View Log',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
              );
            },
          ),
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

    final filteredStudents = students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final name = (s['name'] ?? '').toString().toLowerCase();
      final roll = (s['rollNumber'] ?? '').toString();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || roll.contains(q);
    }).toList();

    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;
    final List<dynamic> absentStudents = [];
    final List<dynamic> lateStudents = [];

    for (final s in students) {
      final status = _attendanceMap[s['_id']] ?? 'PRESENT';
      if (status == 'PRESENT') {
        presentCount++;
      } else if (status == 'ABSENT') {
        absentCount++;
        absentStudents.add(s);
      } else if (status == 'LATE') {
        lateCount++;
        lateStudents.add(s);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Attendance'),
        actions: [
          IconButton(
            tooltip: 'View Daily Log & Reports',
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.accent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoadingDate
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Bar with Calendar picker
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryLight),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      dateDisplay,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_drop_down, color: AppColors.primaryLight, size: 20),
                                  ],
                                ),
                                Text(
                                  _isAlreadyMarked
                                      ? '✅ Attendance Marked (Tap to edit)'
                                      : '⚠️ Attendance Not Marked Yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _isAlreadyMarked ? AppColors.emerald : AppColors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Quick Action: All Present
                        OutlinedButton.icon(
                          onPressed: () => _markAll('PRESENT'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.emerald),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.emerald),
                          label: Text(
                            'All Present',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Summary Counters Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: AppColors.surfaceLight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatPill('Total', students.length, AppColors.textPrimary),
                      _buildStatPill('Present', presentCount, AppColors.emerald),
                      _buildStatPill('Absent', absentCount, AppColors.rose),
                      _buildStatPill('Late', lateCount, AppColors.amber),
                    ],
                  ),
                ),

                // Absent & Late Highlights
                if (absentStudents.isNotEmpty || lateStudents.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (absentStudents.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.cancel_rounded, size: 14, color: AppColors.rose),
                              const SizedBox(width: 6),
                              Text(
                                'Absent Students (${absentStudents.length}): ',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.rose),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: absentStudents.map((s) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.rose.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.rose.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          '#${s['rollNumber']} ${s['name']}',
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.rose),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (lateStudents.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.amber),
                              const SizedBox(width: 6),
                              Text(
                                'Late Students (${lateStudents.length}): ',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.amber),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: lateStudents.map((s) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.amber.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.amber.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          '#${s['rollNumber']} ${s['name']}',
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.amber),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                // Search Filter Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search student name or roll number...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),

                // Student Attendance List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    itemCount: filteredStudents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final studentId = student['_id'];
                      final currentStatus = _attendanceMap[studentId] ?? 'PRESENT';

                      return GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            // Roll badge
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: AppColors.surface,
                              child: Text(
                                '${student['rollNumber'] ?? index + 1}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name & Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'] ?? '',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    currentStatus == 'PRESENT'
                                        ? 'Present'
                                        : currentStatus == 'ABSENT'
                                            ? 'Absent'
                                            : 'Late arrival',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: currentStatus == 'PRESENT'
                                          ? AppColors.emerald
                                          : currentStatus == 'ABSENT'
                                              ? AppColors.rose
                                              : AppColors.amber,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status Toggle Chips (P / A / L)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildChoiceChip(
                                  label: 'P',
                                  tooltip: 'Present',
                                  selected: currentStatus == 'PRESENT',
                                  activeColor: AppColors.emerald,
                                  onTap: () => setState(() => _attendanceMap[studentId] = 'PRESENT'),
                                ),
                                const SizedBox(width: 6),
                                _buildChoiceChip(
                                  label: 'A',
                                  tooltip: 'Absent',
                                  selected: currentStatus == 'ABSENT',
                                  activeColor: AppColors.rose,
                                  onTap: () => setState(() => _attendanceMap[studentId] = 'ABSENT'),
                                ),
                                const SizedBox(width: 6),
                                _buildChoiceChip(
                                  label: 'L',
                                  tooltip: 'Late',
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
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: CustomButton(
                    text: _isAlreadyMarked
                        ? 'Update Attendance ($presentCount P, $absentCount A, $lateCount L)'
                        : 'Save Attendance & Notify Parents',
                    icon: Icons.check_circle_rounded,
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
    required String tooltip,
    required bool selected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
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
      ),
    );
  }
}
