import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // Step 1: Request Email; Step 2: Enter Token & New Password
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestResetToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    final msg = await authProvider.forgotPassword(email);
    if (msg != null && mounted) {
      setState(() {
        _successMessage = msg;
        _currentStep = 2;
      });
    }
  }

  Future<void> _handleResetPassword() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (token.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token and New Password are required')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final msg = await authProvider.resetPassword(token: token, newPassword: newPassword);
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(); // Back to Auth Screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: BoxConstraints(maxWidth: isCompact ? double.infinity : 480),
            child: GlassContainer(
              opacity: 0.12,
              borderRadius: 28,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF818CF8).withOpacity(0.2),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, size: 36, color: Color(0xFF818CF8)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentStep == 1 ? 'Forgot Password?' : 'Reset Your Password',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == 1
                        ? 'Enter your registered email address to receive password reset instructions.'
                        : 'Enter the reset token sent to your email along with your new password.',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  if (_successMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (authProvider.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (_currentStep == 1) ...[
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      onSubmitted: (_) => _handleRequestResetToken(),
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      label: 'Send Reset Instructions',
                      isLoading: authProvider.isLoading,
                      onPressed: _handleRequestResetToken,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 2),
                      child: const Text(
                        'Already have a reset token?',
                        style: TextStyle(color: Color(0xFF818CF8), fontSize: 13),
                      ),
                    ),
                  ] else ...[
                    _buildTextField(
                      controller: _tokenController,
                      hint: 'Reset Token (e.g. from email/logs)',
                      icon: Icons.key_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _newPasswordController,
                      hint: 'New Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureNewPass,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white60,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm New Password',
                      icon: Icons.lock_clock_outlined,
                      obscureText: _obscureConfirmPass,
                      onSubmitted: (_) => _handleResetPassword(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white60,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      label: 'Reset Password',
                      isLoading: authProvider.isLoading,
                      onPressed: _handleResetPassword,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 1),
                      child: const Text(
                        'Back to Email Step',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF818CF8), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
