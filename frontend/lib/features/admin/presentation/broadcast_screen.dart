import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/admin_provider.dart';

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedTarget = 'ALL'; // 'ALL', 'TEACHERS', 'PARENTS'
  bool _isSending = false;

  Future<void> _handleBroadcast() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter announcement title and message')),
      );
      return;
    }

    setState(() => _isSending = true);

    final ok = await ref.read(adminProvider.notifier).sendBroadcast(
          title: title,
          message: message,
          targetRole: _selectedTarget,
        );

    setState(() => _isSending = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Instant broadcast alert dispatched to selected audience! 📢'),
        ),
      );
      Navigator.pop(context);
    } else {
      final err = ref.read(adminProvider).errorMessage ?? 'Broadcast failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.rose, content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Institution-Wide Broadcast'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Target Audience',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAudienceOption('ALL', '📢 All Users', AppColors.primary),
                  const SizedBox(width: 8),
                  _buildAudienceOption('TEACHERS', '👨‍🏫 Teachers', AppColors.emerald),
                  const SizedBox(width: 8),
                  _buildAudienceOption('PARENTS', '👨‍👩‍👧 Parents', AppColors.accent),
                ],
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _titleController,
                label: 'Announcement Headline',
                hint: 'e.g. Annual Sports Meet 2026 Scheduled',
                prefixIcon: Icons.campaign_rounded,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _messageController,
                label: 'Broadcast Content / Notice',
                hint: 'Write complete details of the announcement here...',
                prefixIcon: Icons.edit_note_rounded,
                maxLines: 5,
              ),
              const SizedBox(height: 28),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 24, color: AppColors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Push notification & in-app alerts are delivered in real time to connected devices via Socket.io.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Dispatch Real-Time Broadcast',
                icon: Icons.send_rounded,
                isLoading: _isSending,
                onPressed: _handleBroadcast,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceOption(String target, String label, Color color) {
    final isSelected = _selectedTarget == target;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTarget = target),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
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
