import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/teacher_provider.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherProvider);
    final students = teacherState.students;
    final classInfo = teacherState.classInfo;
    final classroom = classInfo?['classroom'];
    final className = classroom != null
        ? '${classroom['name']} - ${classroom['section']}'
        : 'Assigned Class';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class Students Directory', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('$className • ${students.length} Total Students', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: students.isEmpty
          ? const EmptyState(
              icon: Icons.school_outlined,
              title: 'No Students Enrolled',
              description: 'No student profiles were found in your assigned class.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final student = students[index];
                final parent = student['parentId'] is Map ? student['parentId'] : null;

                return GlassCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailScreen(student: student),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Roll Number Badge
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '#${student['rollNumber'] ?? index + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Student Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'] ?? 'Student Name',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Parent: ${parent?['name'] ?? 'Not Linked'}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Address: ${student['address'] ?? 'Not specified'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
