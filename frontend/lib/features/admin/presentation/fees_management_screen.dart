import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class FeesManagementScreen extends ConsumerStatefulWidget {
  const FeesManagementScreen({super.key});

  @override
  ConsumerState<FeesManagementScreen> createState() => _FeesManagementScreenState();
}

class _FeesManagementScreenState extends ConsumerState<FeesManagementScreen> {
  String _selectedStatus = 'ALL';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadClasses();
      _fetchFees();
    });
  }

  void _fetchFees() {
    ref.read(adminProvider.notifier).loadFees(
          status: _selectedStatus == 'ALL' ? null : _selectedStatus,
          search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        );
  }

  void _showGenerateInvoiceModal(BuildContext context) {
    final classes = ref.read(adminProvider).classes;
    String? selectedClass = classes.isNotEmpty ? classes.first['_id'] : null;
    final titleCtrl = TextEditingController(text: 'Term 2 Tuition Fee');
    final amountCtrl = TextEditingController(text: '12500');
    final dueDateCtrl = TextEditingController(text: '2026-11-15');
    String selectedCategory = 'TUITION';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Generate Fee Invoices',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Generate invoices for an entire class in 1 tap',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                // Class selection
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedClass,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      items: classes.map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem<String>(
                          value: c['_id'],
                          child: Text('${c['name']} - ${c['section']}', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedClass = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Fee Category
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      items: ['TUITION', 'ADMISSION', 'TRANSPORT', 'EXAM', 'ANNUAL', 'OTHER'].map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text('Category: $cat', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedCategory = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(controller: titleCtrl, label: 'Invoice Title (e.g. Q3 Transport Fee)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: amountCtrl,
                        label: 'Amount (₹)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(controller: dueDateCtrl, label: 'Due Date (YYYY-MM-DD)'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Dispatch Invoices',
                  onPressed: () async {
                    if (selectedClass == null || amountCtrl.text.trim().isEmpty) return;

                    final ok = await ref.read(adminProvider.notifier).generateFeeInvoices({
                      'classId': selectedClass,
                      'title': titleCtrl.text.trim(),
                      'feeCategory': selectedCategory,
                      'totalAmount': double.tryParse(amountCtrl.text.trim()) ?? 0,
                      'dueDate': dueDateCtrl.text.trim(),
                    });

                    if (mounted) {
                      Navigator.pop(ctx);
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Class invoices dispatched and parents notified!'),
                            backgroundColor: AppColors.emerald,
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
      ),
    );
  }

  void _showRecordPaymentModal(BuildContext context, dynamic feeRecord) {
    final remaining = (feeRecord['totalAmount'] ?? 0) - (feeRecord['paidAmount'] ?? 0);
    final amtCtrl = TextEditingController(text: remaining.toString());
    String method = 'UPI';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Record Fee Payment',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Student: ${feeRecord['studentId']?['name'] ?? 'Student'}\nInvoice: ${feeRecord['title']}\nRemaining Due: ₹$remaining',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: amtCtrl,
                label: 'Payment Amount (₹)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: method,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    items: ['UPI', 'CASH', 'CHEQUE', 'ONLINE', 'BANK_TRANSFER'].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text('Mode: $m', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => method = val!),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
              onPressed: () async {
                final payAmt = double.tryParse(amtCtrl.text.trim()) ?? 0;
                if (payAmt <= 0) return;

                Navigator.pop(ctx);
                final ok = await ref.read(adminProvider.notifier).recordFeePayment(
                      feeRecord['_id'],
                      payAmt,
                      method: method,
                    );
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment recorded and official receipt generated!'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                }
              },
              child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final overview = adminState.feesOverview;
    final records = adminState.feeRecords;

    final totalBilled = overview?['totalBilled'] ?? 0;
    final totalCollected = overview?['totalCollected'] ?? 0;
    final totalPending = overview?['totalPending'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Fees & Payments Hub',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchFees,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
        label: Text('Generate Invoice', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => _showGenerateInvoiceModal(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchFees(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // KPI Cards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Collected',
                      value: '₹${(totalCollected as num).toLocaleString()}',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.emerald,
                      subtitle: 'Active Academic Term',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Pending Dues',
                      value: '₹${(totalPending as num).toLocaleString()}',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.amber,
                      subtitle: 'Awaiting Payment',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ALL', 'PENDING', 'OVERDUE', 'PAID'].map((st) {
                    final isSel = _selectedStatus == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSel,
                        label: Text(st, style: GoogleFonts.inter(fontSize: 12)),
                        onSelected: (_) {
                          setState(() => _selectedStatus = st);
                          _fetchFees();
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Student Fee Invoices & Records',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              if (adminState.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (records.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_outlined,
                  title: 'No Fee Invoices',
                  message: 'Generate your first class invoice using the button below.',
                )
              else
                ...records.map((r) {
                  final student = r['studentId'];
                  final status = r['status'] ?? 'PENDING';
                  final totalAmt = r['totalAmount'] ?? 0;
                  final paidAmt = r['paidAmount'] ?? 0;
                  final dueAmt = totalAmt - paidAmt;
                  final isPaid = status == 'PAID' || dueAmt <= 0;

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['title'] ?? 'Fee Invoice',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${student?['name'] ?? 'Student'} • ${student?['classId'] != null ? "${student['classId']['name']} - ${student['classId']['section']}" : "Class"}${student?['admissionNumber'] != null ? " • Adm: ${student['admissionNumber']}" : ""}',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              status: status,
                              color: isPaid
                                  ? AppColors.emerald
                                  : status == 'OVERDUE'
                                      ? AppColors.rose
                                      : AppColors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Billed', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                Text('₹$totalAmt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Paid', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                Text('₹$paidAmt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.emerald)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Balance Due', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                Text('₹$dueAmt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: dueAmt > 0 ? AppColors.rose : AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        if (!isPaid) ...[
                          const Divider(color: AppColors.border, height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emerald,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.payment_rounded, size: 16, color: Colors.white),
                              label: const Text('Record Payment', style: TextStyle(color: Colors.white, fontSize: 12)),
                              onPressed: () => _showRecordPaymentModal(context, r),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

extension NumberFormatExtension on num {
  String toLocaleString() {
    return toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
