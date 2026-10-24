import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/super_admin_provider.dart';

class CentralBroadcastScreen extends ConsumerStatefulWidget {
  const CentralBroadcastScreen({super.key});

  @override
  ConsumerState<CentralBroadcastScreen> createState() => _CentralBroadcastScreenState();
}

class _CentralBroadcastScreenState extends ConsumerState<CentralBroadcastScreen> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _targetAudience = 'ALL';
  String? _selectedSchoolId;
  bool _isSending = false;

  final Map<String, String> _audienceOptions = {
    'ALL': 'Entire Platform (All Schools)',
    'ADMINS': 'All School Principals & Admins',
    'TEACHERS': 'All Teaching Faculty',
    'PARENTS': 'All Parents & Guardians',
    'SPECIFIC_SCHOOL': 'Target Specific Campus Only',
  };

  Future<void> _handleTransmit() async {
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide both Announcement Title and Message')),
      );
      return;
    }

    if (_targetAudience == 'SPECIFIC_SCHOOL' && _selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the specific target school')),
      );
      return;
    }

    setState(() => _isSending = true);

    final success = await ref.read(superAdminProvider.notifier).sendBroadcast(
          title: _titleCtrl.text.trim(),
          message: _messageCtrl.text.trim(),
          target: _targetAudience,
          schoolId: _targetAudience == 'SPECIFIC_SCHOOL' ? _selectedSchoolId : null,
        );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      _titleCtrl.clear();
      _messageCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emerald,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Broadcast successfully transmitted across platform!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schools = ref.watch(superAdminProvider).schools;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Central Broadcast Transmitter',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      // STICKY BOTTOM SUBMIT BAR: NEVER HIDDEN!
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Transmit Central Broadcast',
            icon: Icons.send_rounded,
            isLoading: _isSending,
            onPressed: _handleTransmit,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign_rounded, color: AppColors.rose, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Instant Multi-Campus Notification',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pushes immediate high-priority alerts to selected mobile app users.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text('Target Audience Scope', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _targetAudience,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  items: _audienceOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _targetAudience = val ?? 'ALL'),
                ),
              ),
            ),

            if (_targetAudience == 'SPECIFIC_SCHOOL') ...[
              const SizedBox(height: 14),
              Text('Select Specific School', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSchoolId,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    hint: Text('Choose Campus', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                    items: schools.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(s.name, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSchoolId = val),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            CustomTextField(
              controller: _titleCtrl,
              label: 'Announcement Headline *',
              hint: 'e.g. Severe Weather Alert / Campus Holiday',
            ),
            const SizedBox(height: 16),

            Text('Circular / Advisory Content *', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _messageCtrl,
              maxLines: 5,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter complete announcement message to be broadcasted...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
