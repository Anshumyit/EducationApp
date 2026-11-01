import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/admin_provider.dart';

class ClassTimetableScreen extends ConsumerStatefulWidget {
  final dynamic classroom;

  const ClassTimetableScreen({super.key, required this.classroom});

  @override
  ConsumerState<ClassTimetableScreen> createState() => _ClassTimetableScreenState();
}

class _ClassTimetableScreenState extends ConsumerState<ClassTimetableScreen> {
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  String _selectedDay = 'Monday';

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _classroomData;
  Map<String, List<Map<String, dynamic>>> _timetableByDay = {};

  @override
  void initState() {
    super.initState();
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
    final classId = widget.classroom['_id'];
    final data = await ref.read(adminProvider.notifier).fetchClassTimetable(classId);

    if (mounted) {
      if (data != null) {
        _classroomData = data['classroom'];
        final timetableList = (data['timetable'] as List<dynamic>?) ?? [];

        _initDays();
        for (final item in timetableList) {
          final day = item['day']?.toString();
          if (day != null && _timetableByDay.containsKey(day)) {
            final periods = (item['periods'] as List<dynamic>?) ?? [];
            _timetableByDay[day] = periods.map((p) => Map<String, dynamic>.from(p)).toList();
          }
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTimetable() async {
    setState(() => _isSaving = true);
    final classId = widget.classroom['_id'];

    final formattedTimetable = _days.map((day) {
      return {
        'day': day,
        'periods': _timetableByDay[day] ?? [],
      };
    }).toList();

    final ok = await ref.read(adminProvider.notifier).saveClassTimetable(classId, formattedTimetable);

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.emerald,
            content: Text('Timetable & Period schedules saved successfully! 🗓️'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.rose,
            content: Text(ref.read(adminProvider).errorMessage ?? 'Failed to save timetable'),
          ),
        );
      }
    }
  }

  void _showAddOrEditPeriodDialog({Map<String, dynamic>? existingPeriod, int? index}) {
    final teachers = ref.read(adminProvider).teachers;
    final subjects = (_classroomData?['subjects'] as List<dynamic>?) ?? (widget.classroom['subjects'] as List<dynamic>?) ?? [];

    final existingPeriodNum = existingPeriod != null ? existingPeriod['periodNumber'] : null;
    final periodNumCtrl = TextEditingController(
      text: existingPeriodNum != null
          ? '$existingPeriodNum'
          : '${(_timetableByDay[_selectedDay]?.length ?? 0) + 1}',
    );

    final existingSubject = existingPeriod != null ? existingPeriod['subject']?.toString() : null;
    final existingStartTime = existingPeriod != null ? existingPeriod['startTime']?.toString() : null;
    final existingEndTime = existingPeriod != null ? existingPeriod['endTime']?.toString() : null;
    final existingRoom = existingPeriod != null ? existingPeriod['roomNumber']?.toString() : null;
    final classroomRoom = widget.classroom != null ? widget.classroom['roomNumber']?.toString() : null;

    final subjectCtrl = TextEditingController(
      text: existingSubject ?? (subjects.isNotEmpty ? subjects.first['name']?.toString() ?? 'Mathematics' : 'Mathematics'),
    );
    final startTimeCtrl = TextEditingController(text: existingStartTime ?? '08:30 AM');
    final endTimeCtrl = TextEditingController(text: existingEndTime ?? '09:15 AM');
    final roomCtrl = TextEditingController(text: existingRoom ?? classroomRoom ?? 'Room 101');

    String? selectedTeacherId;
    String? selectedTeacherName;

    if (existingPeriod != null) {
      final t = existingPeriod['teacher'];
      if (t is Map) {
        selectedTeacherId = t['_id']?.toString();
      } else if (t != null) {
        selectedTeacherId = t.toString();
      }
      selectedTeacherName = existingPeriod['teacherName']?.toString();
    }

    if (selectedTeacherId == null && teachers.isNotEmpty) {
      selectedTeacherId = teachers.first['_id'];
      selectedTeacherName = teachers.first['name'];
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existingPeriod != null ? 'Edit Period Schedule' : 'Add Teaching Period',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Assign lecture timing, subject & teacher for $_selectedDay',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Period Number & Room
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        controller: periodNumCtrl,
                        label: 'Period #',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: roomCtrl,
                        label: 'Room No.',
                        hint: 'e.g. Room 204',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Subject Name / Dropdown
                Text('Subject Name', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                if (subjects.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        hint: const Text('Select from class subjects'),
                        value: subjects.any((s) => s['name'] == subjectCtrl.text) ? subjectCtrl.text : null,
                        items: subjects.map<DropdownMenuItem<String>>((s) {
                          return DropdownMenuItem<String>(
                            value: s['name'].toString(),
                            child: Text(s['name'].toString(), style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              subjectCtrl.text = val;
                              // Auto match subject's assigned teacher if any
                              final match = subjects.firstWhere((s) => s['name'] == val, orElse: () => null);
                              if (match != null && match['teacher'] != null) {
                                final tid = match['teacher'] is Map ? match['teacher']['_id'] : match['teacher'];
                                if (tid != null) {
                                  selectedTeacherId = tid;
                                  final tObj = teachers.firstWhere((t) => t['_id'] == tid, orElse: () => null);
                                  if (tObj != null) selectedTeacherName = tObj['name'];
                                }
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),

                CustomTextField(
                  controller: subjectCtrl,
                  label: 'Subject (Custom / Selected)',
                  hint: 'e.g. Mathematics, Physics',
                ),
                const SizedBox(height: 12),

                // Assign Teacher Dropdown
                Text('Assign Teacher', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      value: selectedTeacherId,
                      hint: const Text('Select Faculty Teacher'),
                      items: teachers.map<DropdownMenuItem<String>>((t) {
                        return DropdownMenuItem<String>(
                          value: t['_id'],
                          child: Text(
                            '${t['name']} (${(t['subjects'] as List? ?? []).join(", ")})',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedTeacherId = val;
                          final match = teachers.firstWhere((t) => t['_id'] == val, orElse: () => null);
                          selectedTeacherName = match?['name'] ?? '';
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Start & End Times
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: startTimeCtrl,
                        label: 'Start Time',
                        hint: '08:30 AM',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        controller: endTimeCtrl,
                        label: 'End Time',
                        hint: '09:15 AM',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Fast Time Presets
                Text('Quick Timing Presets:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    {'start': '08:30 AM', 'end': '09:15 AM'},
                    {'start': '09:15 AM', 'end': '10:00 AM'},
                    {'start': '10:00 AM', 'end': '10:45 AM'},
                    {'start': '11:15 AM', 'end': '12:00 PM'},
                    {'start': '12:00 PM', 'end': '12:45 PM'},
                  ].map((preset) {
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          startTimeCtrl.text = preset['start']!;
                          endTimeCtrl.text = preset['end']!;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${preset['start']} - ${preset['end']}',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                if (subjectCtrl.text.trim().isEmpty) return;

                final periodObj = {
                  'periodNumber': int.tryParse(periodNumCtrl.text.trim()) ?? 1,
                  'subject': subjectCtrl.text.trim(),
                  'startTime': startTimeCtrl.text.trim(),
                  'endTime': endTimeCtrl.text.trim(),
                  'roomNumber': roomCtrl.text.trim(),
                  'teacher': selectedTeacherId,
                  'teacherName': selectedTeacherName ?? '',
                };

                setState(() {
                  if (existingPeriod != null && index != null) {
                    _timetableByDay[_selectedDay]![index] = periodObj;
                  } else {
                    _timetableByDay[_selectedDay]!.add(periodObj);
                  }
                  // Sort periods by periodNumber
                  _timetableByDay[_selectedDay]!.sort((a, b) {
                    final aNum = int.tryParse(a['periodNumber']?.toString() ?? '0') ?? 0;
                    final bNum = int.tryParse(b['periodNumber']?.toString() ?? '0') ?? 0;
                    return aNum.compareTo(bNum);
                  });
                });

                Navigator.pop(ctx);
              },
              child: Text(existingPeriod != null ? 'Update' : 'Add Period', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePeriod(int index) {
    setState(() {
      _timetableByDay[_selectedDay]?.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final className = '${widget.classroom['name']} - ${widget.classroom['section']}';
    final periods = _timetableByDay[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$className Timetable', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Assign Teaching Periods & Teachers', style: GoogleFonts.inter(fontSize: 12, color: AppColors.emerald)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                : TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                    label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _saveTimetable,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Period ($_selectedDay)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => _showAddOrEditPeriodDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Day Tabs Strip
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _days.map((day) {
                        final isSelected = day == _selectedDay;
                        final count = _timetableByDay[day]?.length ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedDay = day),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    day,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$count',
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
                ),

                const Divider(color: AppColors.border, height: 1),

                // Periods List
                Expanded(
                  child: periods.isEmpty
                      ? EmptyState(
                          icon: Icons.access_time_rounded,
                          title: 'No Periods on $_selectedDay',
                          message: 'Tap the button below to assign teaching time and subject to a teacher.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                          itemCount: periods.length,
                          itemBuilder: (context, index) {
                            final p = periods[index];
                            final periodNumber = p['periodNumber'] ?? (index + 1);
                            final subject = p['subject'] ?? 'Subject';
                            final startTime = p['startTime'] ?? '--:--';
                            final endTime = p['endTime'] ?? '--:--';
                            final teacherName = p['teacherName'] ?? 'Unassigned Teacher';
                            final String roomStr = (p['roomNumber'] ?? widget.classroom['roomNumber'] ?? '').toString();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Period Circle
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'P$periodNumber',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                subject,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceVariant,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '$startTime - $endTime',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.emerald,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.person_pin_rounded, size: 14, color: AppColors.accent),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Teacher: $teacherName',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (roomStr.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  '• $roomStr',
                                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Actions
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryLight),
                                      onPressed: () => _showAddOrEditPeriodDialog(existingPeriod: p, index: index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rose),
                                      onPressed: () => _deletePeriod(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

