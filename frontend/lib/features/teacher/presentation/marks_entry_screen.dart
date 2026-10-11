import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/teacher_provider.dart';

class MarksEntryScreen extends ConsumerStatefulWidget {
  const MarksEntryScreen({super.key});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  String _selectedExamType = 'WEEKLY'; // WEEKLY, MONTHLY, HALF_YEARLY, ANNUAL
  final _titleController = TextEditingController(text: 'Weekly Assessment Unit 2');
  String? _selectedStudentId;

  // Subject mark controllers
  final List<Map<String, TextEditingController>> _subjectRows = [
    {
      'name': TextEditingController(text: 'Mathematics'),
      'max': TextEditingController(text: '25'),
      'obtained': TextEditingController(text: '23'),
    },
    {
      'name': TextEditingController(text: 'Physics'),
      'max': TextEditingController(text: '25'),
      'obtained': TextEditingController(text: '21'),
    },
    {
      'name': TextEditingController(text: 'English'),
      'max': TextEditingController(text: '25'),
      'obtained': TextEditingController(text: '24'),
    },
    {
      'name': TextEditingController(text: 'Social Science'),
      'max': TextEditingController(text: '25'),
      'obtained': TextEditingController(text: '22'),
    },
  ];

  bool _isSubmitting = false;

  void _onExamTypeChanged(String type) {
    setState(() {
      _selectedExamType = type;
      if (type == 'WEEKLY') {
        _titleController.text = 'Weekly Test Unit 2';
        for (var row in _subjectRows) {
          row['max']!.text = '25';
          row['obtained']!.text = '22';
        }
      } else if (type == 'MONTHLY') {
        _titleController.text = 'October Monthly Assessment';
        for (var row in _subjectRows) {
          row['max']!.text = '100';
          row['obtained']!.text = '88';
        }
      } else if (type == 'HALF_YEARLY') {
        _titleController.text = 'Mid-Term (6 Months) Examination';
        for (var row in _subjectRows) {
          row['max']!.text = '100';
          row['obtained']!.text = '92';
        }
      } else if (type == 'ANNUAL') {
        _titleController.text = 'Annual Board Final Exam (1 Year)';
        for (var row in _subjectRows) {
          row['max']!.text = '100';
          row['obtained']!.text = '95';
        }
      }
    });
  }

  void _addSubjectRow() {
    setState(() {
      _subjectRows.add({
        'name': TextEditingController(text: 'Computer Science'),
        'max': TextEditingController(text: _selectedExamType == 'WEEKLY' ? '25' : '100'),
        'obtained': TextEditingController(text: '0'),
      });
    });
  }

  Future<void> _submitMarks() async {
    final teacherState = ref.read(teacherProvider);
    final classId = teacherState.classInfo?['classroom']?['_id'];

    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }

    if (classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class information not found')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final subjects = _subjectRows.map((row) {
      final name = row['name']!.text.trim();
      final max = double.tryParse(row['max']!.text.trim()) ?? 100;
      final obtained = double.tryParse(row['obtained']!.text.trim()) ?? 0;
      return {
        'subjectName': name,
        'maxMarks': max,
        'marksObtained': obtained,
      };
    }).toList();

    final ok = await ref.read(teacherProvider.notifier).recordExamMarks(
          studentId: _selectedStudentId!,
          classId: classId,
          examType: _selectedExamType,
          examTitle: _titleController.text.trim(),
          subjects: subjects,
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Marks submitted successfully & parent notified in real time! 📊'),
        ),
      );
      Navigator.pop(context);
    } else {
      final err = ref.read(teacherProvider).errorMessage ?? 'Failed to submit marks';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.rose, content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(teacherProvider).students;
    if (_selectedStudentId == null && students.isNotEmpty) {
      _selectedStudentId = students[0]['_id'];
    }

    // Compute live total & percentage
    double totalMax = 0;
    double totalObtained = 0;
    for (var r in _subjectRows) {
      totalMax += double.tryParse(r['max']!.text) ?? 0;
      totalObtained += double.tryParse(r['obtained']!.text) ?? 0;
    }
    final percentage = totalMax > 0 ? ((totalObtained / totalMax) * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Exam Marks Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exam Type Category
            Text(
              'Select Exam Assessment Term',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _buildExamTab('WEEKLY', 'Weekly', AppColors.accent),
                const SizedBox(width: 6),
                _buildExamTab('MONTHLY', 'Monthly', AppColors.primary),
                const SizedBox(width: 6),
                _buildExamTab('HALF_YEARLY', '6 Months', AppColors.amber),
                const SizedBox(width: 6),
                _buildExamTab('ANNUAL', '1 Year', AppColors.emerald),
              ],
            ),

            const SizedBox(height: 20),

            // Exam Title
            CustomTextField(
              controller: _titleController,
              label: 'Exam Title / Name',
              hint: 'e.g. Weekly Test - Unit 2',
              prefixIcon: Icons.assignment_outlined,
            ),

            const SizedBox(height: 16),

            // Select Student Dropdown
            Text(
              'Target Student',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStudentId,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  items: students.map<DropdownMenuItem<String>>((s) {
                    return DropdownMenuItem<String>(
                      value: s['_id'],
                      child: Text(
                        'Roll #${s['rollNumber']} - ${s['name']}',
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedStudentId = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Subject marks rows header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subject-Wise Marks',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSubjectRow,
                  icon: const Icon(Icons.add, size: 16, color: AppColors.accent),
                  label: Text('Add Subject', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.accent)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dynamic subject rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subjectRows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final row = _subjectRows[idx];
                return GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: row['name'],
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            hintText: 'Subject',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: row['obtained'],
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.emerald),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            hintText: 'Obtained',
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('/', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: row['max'],
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            hintText: 'Max',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Summary Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              gradient: AppColors.cardGradient,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Total Obtained', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        '${totalObtained.toInt()} / ${totalMax.toInt()}',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  Column(
                    children: [
                      Text('Percentage', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        '$percentage%',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.emerald),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            CustomButton(
              text: 'Publish Result & Notify Parent',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitMarks,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExamTab(String type, String label, Color color) {
    final isSelected = _selectedExamType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onExamTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
