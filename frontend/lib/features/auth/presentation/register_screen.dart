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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'ADMIN'; // 'ADMIN', 'TEACHER', 'PARENT'

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subjectsController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _addressController = TextEditingController();

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    final password = _passwordController.text;

    if (email == null && phone == null) {
      _showError('Please provide either an Email address or Mobile Number.');
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);

    if (_selectedRole == 'ADMIN') {
      final success = await authNotifier.registerAdmin(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (!mounted) return;

      if (success) {
        final lastOtp = ref.read(authProvider).lastGeneratedOtp;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(testOtp: lastOtp)),
        );
      } else {
        _showError(ref.read(authProvider).errorMessage);
      }
    } else if (_selectedRole == 'TEACHER') {
      final subjects = _subjectsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final success = await authNotifier.registerTeacher(
        name: name,
        email: email,
        phone: phone,
        password: password,
        subjects: subjects,
        qualification: _qualificationController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        );
      } else {
        _showError(ref.read(authProvider).errorMessage);
      }
    } else if (_selectedRole == 'PARENT') {
      final success = await authNotifier.registerParent(
        name: name,
        email: email,
        phone: phone,
        password: password,
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        );
      } else {
        _showError(ref.read(authProvider).errorMessage);
      }
    }
  }

  void _showError(String? msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg ?? 'Registration failed. Please check inputs.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Portal Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select Your Institutional Role',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Role selector tabs
                Row(
                  children: [
                    _buildRoleTab('ADMIN', '👑 Admin', AppColors.primary),
                    const SizedBox(width: 8),
                    _buildRoleTab('TEACHER', '👨‍🏫 Teacher', AppColors.emerald),
                    const SizedBox(width: 8),
                    _buildRoleTab('PARENT', '👨‍👩‍👧 Parent', AppColors.accent),
                  ],
                ),
                const SizedBox(height: 24),

                // Common Inputs
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Legal Name',
                  hint: _selectedRole == 'ADMIN'
                      ? 'e.g. Dr. Ramesh Sharma'
                      : _selectedRole == 'TEACHER'
                          ? 'e.g. Anita Desai'
                          : 'e.g. Rajesh Kumar',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'name@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Mobile Contact Number',
                  hint: 'e.g. 9876543210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Secret Password',
                  hint: 'Min 6 characters',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) => v == null || v.length < 6 ? 'Password must be 6+ chars' : null,
                ),
                const SizedBox(height: 16),

                // Role-Specific Inputs
                if (_selectedRole == 'TEACHER') ...[
                  CustomTextField(
                    controller: _subjectsController,
                    label: 'Subjects Taught (comma-separated)',
                    hint: 'e.g. Mathematics, Physics, Chemistry',
                    prefixIcon: Icons.menu_book_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Subjects required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _qualificationController,
                    label: 'Highest Educational Qualification',
                    hint: 'e.g. M.Sc. Mathematics, B.Ed.',
                    prefixIcon: Icons.workspace_premium_outlined,
                  ),
                  const SizedBox(height: 16),
                ],

                if (_selectedRole == 'PARENT') ...[
                  CustomTextField(
                    controller: _addressController,
                    label: 'Residential Address',
                    hint: 'Flat/House No, Street, City',
                    prefixIcon: Icons.home_outlined,
                    maxLines: 2,
                    validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Approval policy note for Teacher / Parent
                if (_selectedRole != 'ADMIN')
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_outlined, size: 20, color: AppColors.amber),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Note: Teacher & Parent registrations require Admin verification before login is enabled.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                CustomButton(
                  text: _selectedRole == 'ADMIN' ? 'Register & Verify OTP' : 'Submit Registration',
                  icon: Icons.app_registration_rounded,
                  isLoading: authState.isLoading,
                  onPressed: _handleRegister,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.outfit(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role, String label, Color color) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
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
                fontSize: 13,
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
