import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/parent_provider.dart';

class FeeManagementScreen extends ConsumerWidget {
  const FeeManagementScreen({super.key});

  void _showPaymentDialog(BuildContext context, WidgetRef ref, dynamic feeRecord) {
    final remainingDue = (feeRecord['totalAmount'] ?? 0) - (feeRecord['paidAmount'] ?? 0);
    final amountController = TextEditingController(text: remainingDue.toString());
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final mediaQuery = MediaQuery.of(ctx);
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: mediaQuery.viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Online Fee Installment',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paying for ${feeRecord['title'] ?? 'School Tuition'}',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: amountController,
                      label: 'Payment Amount (₹)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.currency_rupee_rounded,
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.security_rounded, size: 20, color: AppColors.emerald),
                          const SizedBox(width: 10),
                          Text(
                            '256-bit encrypted secure educational gateway',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Confirm & Pay Installment',
                      icon: Icons.lock_outline_rounded,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final amount = double.tryParse(amountController.text) ?? 0;
                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid payment amount'),
                                    backgroundColor: AppColors.rose,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final ok = await ref.read(parentProvider.notifier).payFee(feeRecord['_id'], amount);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.emerald,
                                      content: Text('Payment of ₹$amount successful & receipt generated! 💳'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.rose,
                                      content: Text('Payment transaction could not be processed'),
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentState = ref.watch(parentProvider);
    final feeData = parentState.feeData;
    final child = parentState.currentChild;
    final childName = child?['name'] ?? 'Child';

    final totalFee = feeData?['totalFee'] ?? 0;
    final totalPaid = feeData?['totalPaid'] ?? 0;
    final totalPending = feeData?['totalPending'] ?? 0;
    final records = (feeData?['records'] as List<dynamic>? ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$childName - Fee Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Balance Banner
            GlassCard(
              padding: const EdgeInsets.all(22),
              gradient: AppColors.primaryGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining Dues Balance',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${totalPending.toString()}',
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Billed', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text('₹$totalFee', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(width: 1, height: 26, color: Colors.white24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid So Far', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text('₹$totalPaid', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Fee Breakdown & Invoices',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (records.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No Fee Invoices',
                description: 'There are no active fee records pending for this academic session.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final rec = records[index];
                  final dueDate = rec['dueDate'] != null
                      ? DateFormat('MMM d, yyyy').format(DateTime.parse(rec['dueDate']))
                      : '';
                  final status = rec['status'] ?? 'PENDING';
                  final dueAmount = (rec['totalAmount'] ?? 0) - (rec['paidAmount'] ?? 0);

                  return GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rec['title'] ?? 'Tuition Fee',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            StatusBadge(status: status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Invoice Amount:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                            Text('₹${rec['totalAmount']}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Paid Amount:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                            Text('₹${rec['paidAmount']}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.emerald)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Due Date:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                            Text(dueDate, style: GoogleFonts.inter(fontSize: 13, color: AppColors.amber)),
                          ],
                        ),

                        if (dueAmount > 0) ...[
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Pay Remaining ₹$dueAmount',
                            icon: Icons.payment_rounded,
                            height: 42,
                            onPressed: () => _showPaymentDialog(context, ref, rec),
                          ),
                        ],
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
