import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  bool _isSignup = false;
  bool _isResetting = false;
  bool _showPassword = false;
  bool _showNewPassword = false;
  bool _isLoading = false;

  final _nameController        = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _newPasswordController = TextEditingController();

  String _errorMessage = '';

  late AnimationController _cardController;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _cardFade  = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
  }

  // ── Validation ────────────────────────────────────────────────

  bool _validatePassword(String p) =>
      p.length >= 8 && RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(p);

  // ── Actions ───────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isSignup) {
        if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(_nameController.text.trim())) {
          throw Exception('Name should only contain alphabets and spaces.');
        }
        if (!_validatePassword(_passwordController.text)) {
          throw Exception(
              'Password must be at least 8 characters long and contain at least one special character.');
        }
        final res = await ApiService.signup(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (res.statusCode == 201 || res.statusCode == 200) {
          AppSnackBar.success(context, 'Account created! Please sign in.');
          setState(() {
            _isSignup = false;
            _passwordController.clear();
            _errorMessage = '';
          });
        } else {
          final body = jsonDecode(res.body);
          throw Exception(body['message'] ?? 'Signup failed');
        }
      } else {
        final res = await ApiService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (res.statusCode == 200) {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        } else {
          final body = jsonDecode(res.body);
          throw Exception(body['message'] ?? 'Login failed');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReset() async {
    final newPass = _newPasswordController.text;
    if (!_validatePassword(newPass)) {
      AppSnackBar.error(context,
          'Password must be at least 8 characters with a special character.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.resetPassword(
        _emailController.text.trim(),
        newPass,
      );
      if (res.statusCode == 200) {
        AppSnackBar.success(context, 'Password reset! Please sign in.');
        setState(() {
          _isResetting = false;
          _newPasswordController.clear();
          _passwordController.clear();
        });
      } else {
        final body = jsonDecode(res.body);
        throw Exception(body['message'] ?? 'Reset failed');
      }
    } catch (e) {
      AppSnackBar.error(
          context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() {
    if (_emailController.text.trim().isEmpty) {
      AppSnackBar.info(context, 'Please enter your email address first.');
      return;
    }
    setState(() => _isResetting = true);
  }

  void _toggleMode() {
    setState(() {
      _isSignup = !_isSignup;
      _errorMessage = '';
    });
    _cardController.forward(from: 0);
  }

  @override
  void dispose() {
    _cardController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppTheme.darkBackground, AppTheme.darkSurface]
                : [AppTheme.surfaceLight, const Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──
                  _buildLogo(),
                  const SizedBox(height: 32),

                  // ── Card ──
                  SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isResetting
                                  ? _buildResetForm()
                                  : _buildAuthForm(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Toggle link ──
                  if (!_isResetting) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignup
                              ? "Already have an account?"
                              : "Don't have an account?",
                          style: const TextStyle(
                              color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(_isSignup ? 'Sign In' : 'Sign Up'),
                        ),
                      ],
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.phone_in_talk_rounded,
              color: Colors.white, size: 38),
        ),
        const SizedBox(height: 16),
        const Text(
          'NexCall',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'AI Voice Agent Platform',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Column(
      key: ValueKey(_isSignup),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isSignup ? 'Create Account' : 'Welcome Back',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _isSignup
              ? 'Start building AI voice agents today'
              : 'Sign in to your account to continue',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Error banner
        if (_errorMessage.isNotEmpty) ...[
          _ErrorBanner(message: _errorMessage),
          const SizedBox(height: 16),
        ],

        // Name field (signup only)
        if (_isSignup) ...[
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (val) =>
                (val == null || val.isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 14),
        ],

        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Please enter your email';
            if (!val.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_showPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () =>
                  setState(() => _showPassword = !_showPassword),
            ),
          ),
          validator: (val) =>
              (val == null || val.isEmpty) ? 'Please enter your password' : null,
        ),

        // Forgot password
        if (!_isSignup) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              child: const Text('Forgot Password?'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
        ],

        // Submit button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(_isSignup ? 'Create Account' : 'Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    return Column(
      key: const ValueKey('reset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              onPressed: () => setState(() => _isResetting = false),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 4),
            Text(
              'Reset Password',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter a new password for your account',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Email (read-only, prefilled)
        TextFormField(
          controller: _emailController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),

        // New password
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_showNewPassword,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              icon: Icon(_showNewPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
            ),
          ),
          validator: (val) =>
              (val == null || val.isEmpty) ? 'Enter a new password' : null,
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitReset,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Reset Password'),
          ),
        ),
      ],
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.errorRedLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorRedBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
