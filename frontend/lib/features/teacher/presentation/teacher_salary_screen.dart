import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/teacher_provider.dart';

class TeacherSalaryScreen extends ConsumerWidget {
  const TeacherSalaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherProvider);
    final slips = teacherState.salarySlips;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Salary & Pay Slips'),
      ),
      body: slips.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Pay Slips Issued',
              description: 'Salary slips issued by school administration will appear here.',
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(teacherProvider.notifier).loadDashboard(),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: slips.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final slip = slips[index];
                  final netSalary = slip['netSalary'] ?? 0;
                  final month = slip['month'] ?? '';
                  final year = slip['year'] ?? '';

                  return GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salary Slip: $month $year',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Slip ID: ${slip['slipNumber'] ?? 'PAY-2026'}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            StatusBadge(status: slip['paymentStatus'] ?? 'PAID'),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 16),

                        // Earnings
                        _buildSalaryLine('Basic Salary', '₹${slip['basicSalary'] ?? 0}'),
                        _buildSalaryLine('House Rent Allowance (HRA)', '₹${slip['hra'] ?? 0}'),
                        _buildSalaryLine('Dearness Allowance (DA)', '₹${slip['da'] ?? 0}'),
                        _buildSalaryLine('Special Allowance', '₹${slip['specialAllowance'] ?? 0}'),

                        const SizedBox(height: 8),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 8),

                        // Deductions
                        _buildSalaryLine('Provident Fund (PF)', '- ₹${slip['pfDeduction'] ?? 0}', isDeduction: true),
                        _buildSalaryLine('Tax Deduction', '- ₹${slip['taxDeduction'] ?? 0}', isDeduction: true),

                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Net Disbursed Salary',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emerald,
                                ),
                              ),
                              Text(
                                '₹${netSalary.toString()}',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Download Salary Receipt (PDF)',
                          icon: Icons.download_rounded,
                          isOutlined: true,
                          height: 44,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.emerald,
                                content: Text('Salary receipt for $month $year downloaded to device storage! 📄'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildSalaryLine(String label, String amount, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            amount,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDeduction ? AppColors.rose : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
