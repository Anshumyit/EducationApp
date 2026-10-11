import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';
import 'pending_approval_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController(text: 'admin@school.com');
  final _passwordController = TextEditingController(text: 'Password@123');
  final _formKey = GlobalKey<FormState>();

  void _fillDemo(String id, String pwd) {
    setState(() {
      _identifierController.text = id;
      _passwordController.text = pwd;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _identifierController.text.trim(),
          _passwordController.text,
        );

    final authState = ref.read(authProvider);

    if (!mounted) return;

    if (!success) {
      if (authState.isPendingApproval) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        );
      } else if (authState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.rose,
            content: Text(
              authState.errorMessage!,
              style: GoogleFonts.inter(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Logo & Header
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school_rounded, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'ScholarCloud OS',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Next-Gen Unified School Management Suite',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Demo Preset Selector
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Demo Roles (1-Tap Login):',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildRoleChip(
                            label: '👑 Admin',
                            color: AppColors.primary,
                            onTap: () => _fillDemo('admin@school.com', 'Password@123'),
                          ),
                          _buildRoleChip(
                            label: '👨‍🏫 Class Teacher',
                            color: AppColors.emerald,
                            onTap: () => _fillDemo('teacher.rahul@school.com', 'Password@123'),
                          ),
                          _buildRoleChip(
                            label: '👨‍👩‍👧 Parent',
                            color: AppColors.accent,
                            onTap: () => _fillDemo('parent.rajesh@gmail.com', 'Password@123'),
                          ),
                          _buildRoleChip(
                            label: '⏳ Pending Teacher',
                            color: AppColors.amber,
                            onTap: () => _fillDemo('teacher.amit@school.com', 'Password@123'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Form Fields
                CustomTextField(
                  controller: _identifierController,
                  label: 'Email or Mobile Number',
                  hint: 'Enter your email or phone',
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Please enter email or phone' : null,
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) => v == null || v.length < 6 ? 'Password must be 6+ characters' : null,
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Sign In to Portal',
                  icon: Icons.login_rounded,
                  isLoading: authState.isLoading,
                  onPressed: _handleLogin,
                ),

                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don’t have an account? ',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Register Now',
                        style: GoogleFonts.outfit(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
