import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_widgets.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatelessWidget {
  final int initialTabIndex;
  final VoidCallback? onSuccess;

  const AuthScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Stack(
        children: [
          // Background Glow Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x886366F1), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x8806B6D4), Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: AuthCardWidget(
                initialTabIndex: initialTabIndex,
                onSuccess: onSuccess,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCardWidget extends StatefulWidget {
  final int initialTabIndex;
  final VoidCallback? onSuccess;

  const AuthCardWidget({
    super.key,
    this.initialTabIndex = 0,
    this.onSuccess,
  });

  @override
  State<AuthCardWidget> createState() => _AuthCardWidgetState();
}

class _AuthCardWidgetState extends State<AuthCardWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;

  // Register Controllers
  final _regUsernameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regFullNameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _regObscurePassword = true;
  bool _regObscureConfirmPassword = true;

  // Password strength check
  String _password = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _regPasswordController.addListener(() {
      setState(() {
        _password = _regPasswordController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regFullNameController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _password.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_password);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_password);
  bool get _hasDigits => RegExp(r'[0-9]').hasMatch(_password);
  bool get _hasSpecial => RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?]').hasMatch(_password);

  double get _passwordStrength {
    if (_password.isEmpty) return 0.0;
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigits) score++;
    if (_hasSpecial) score++;
    return score / 5.0;
  }

  Color get _strengthColor {
    final strength = _passwordStrength;
    if (strength <= 0.2) return Colors.redAccent;
    if (strength <= 0.6) return Colors.orangeAccent;
    if (strength <= 0.8) return Colors.blueAccent;
    return Colors.greenAccent;
  }

  Future<void> _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _loginIdentifierController.text.trim();
    final password = _loginPasswordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final success = await authProvider.login(
      identifier: identifier,
      password: password,
    );

    if (success && mounted) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleRegister() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = _regUsernameController.text.trim();
    final email = _regEmailController.text.trim();
    final fullName = _regFullNameController.text.trim();
    final password = _regPasswordController.text;
    final confirmPassword = _regConfirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username, Email, and Password are required')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_passwordStrength < 0.8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password does not meet complexity requirements')),
      );
      return;
    }

    final success = await authProvider.register(
      email: email,
      username: username,
      password: password,
      fullName: fullName.isEmpty ? null : fullName,
    );

    if (success && mounted) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isCompact ? double.infinity : 480,
      ),
      child: GlassContainer(
        opacity: 0.12,
        borderRadius: 28,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Logo & Branding
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(
                Icons.sports_tennis_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sports App Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in or create an account to access statistics',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Glass Tab Selector
            Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                labelPadding: EdgeInsets.zero,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.6),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(text: 'Sign In'),
                  Tab(text: 'Register'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Error Alert Banner
            if (authProvider.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      onPressed: () => authProvider.clearError(),
                    )
                  ],
                ),
              ),

            // Tab View Body
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── LOGIN FORM ───────────────────────────────────
                  _buildLoginForm(authProvider),

                  // ── REGISTER FORM ────────────────────────────────
                  _buildRegisterForm(authProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Login Form Builder ─────────────────────────────────────────────────────
  Widget _buildLoginForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildTextField(
            controller: _loginIdentifierController,
            hint: 'Username or Email',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _loginPasswordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _loginObscurePassword,
            onSubmitted: (_) => _handleLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white60,
                size: 20,
              ),
              onPressed: () => setState(() => _loginObscurePassword = !_loginObscurePassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: 'Sign In',
            isLoading: authProvider.isLoading,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }

  // ── Register Form Builder ──────────────────────────────────────────────────
  Widget _buildRegisterForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildTextField(
            controller: _regUsernameController,
            hint: 'Username (min 3 chars)',
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _regEmailController,
            hint: 'Email Address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _regFullNameController,
            hint: 'Full Name (Optional)',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _regPasswordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _regObscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _regObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white60,
                size: 20,
              ),
              onPressed: () => setState(() => _regObscurePassword = !_regObscurePassword),
            ),
          ),
          if (_password.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _passwordStrength,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(_strengthColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildCriterionBadge('8+ Chars', _hasMinLength),
                _buildCriterionBadge('ABC', _hasUppercase),
                _buildCriterionBadge('abc', _hasLowercase),
                _buildCriterionBadge('123', _hasDigits),
                _buildCriterionBadge(r'#$@', _hasSpecial),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _buildTextField(
            controller: _regConfirmPasswordController,
            hint: 'Confirm Password',
            icon: Icons.lock_clock_outlined,
            obscureText: _regObscureConfirmPassword,
            onSubmitted: (_) => _handleRegister(),
            suffixIcon: IconButton(
              icon: Icon(
                _regObscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white60,
                size: 20,
              ),
              onPressed: () => setState(() => _regObscureConfirmPassword = !_regObscureConfirmPassword),
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            label: 'Create Account',
            isLoading: authProvider.isLoading,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────
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

  Widget _buildCriterionBadge(String text, bool met) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: met ? Colors.greenAccent.withOpacity(0.2) : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: met ? Colors.greenAccent.withOpacity(0.4) : Colors.white10,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 12,
            color: met ? Colors.greenAccent : Colors.white38,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met ? Colors.greenAccent : Colors.white54,
            ),
          ),
        ],
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
