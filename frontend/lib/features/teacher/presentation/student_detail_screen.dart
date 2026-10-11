import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import 'attendance_report_screen.dart';

class StudentDetailScreen extends StatelessWidget {
  final dynamic student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final parent = student['parentId'] is Map ? student['parentId'] : null;
    final classroom = student['classId'] is Map ? student['classId'] : null;
    final className = classroom != null ? '${classroom['name']} - ${classroom['section']}' : 'Class';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Full Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      student['name'] != null && student['name'].toString().isNotEmpty
                          ? student['name'][0].toUpperCase()
                          : 'S',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    student['name'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll #${student['rollNumber']} • $className',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admission: ${student['admissionNumber'] ?? 'N/A'}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Guardian / Parent Card
            Text(
              'Parent & Guardian Details',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildDetailRow(Icons.person_rounded, 'Parent Name', parent?['name'] ?? 'Not Linked'),
                  const Divider(color: AppColors.border, height: 20),
                  _buildDetailRow(Icons.phone_rounded, 'Contact Phone', parent?['phone'] ?? student['emergencyContact'] ?? 'N/A'),
                  const Divider(color: AppColors.border, height: 20),
                  _buildDetailRow(Icons.email_rounded, 'Email Address', parent?['email'] ?? 'N/A'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Personal & Medical Card
            Text(
              'Personal & Address Information',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildDetailRow(Icons.home_rounded, 'Residential Address', student['address'] ?? 'N/A'),
                  const Divider(color: AppColors.border, height: 20),
                  _buildDetailRow(Icons.contact_emergency_rounded, 'Emergency Contact', student['emergencyContact'] ?? 'N/A'),
                  const Divider(color: AppColors.border, height: 20),
                  _buildDetailRow(Icons.bloodtype_rounded, 'Blood Group', student['bloodGroup'] ?? 'O+'),
                  const Divider(color: AppColors.border, height: 20),
                  _buildDetailRow(Icons.wc_rounded, 'Gender', student['gender'] ?? 'MALE'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick navigation to Attendance Calendar
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceReportScreen(
                      studentId: student['_id'],
                      studentName: student['name'],
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primaryLight),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'View Student Monthly Attendance Report',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryLight),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
