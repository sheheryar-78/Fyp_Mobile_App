import 'dart:convert';
import 'package:flutter/material';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isSignup = false;
  bool _isResetting = false;
  bool _showPassword = false;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String _errorMessage = "";

  // Validation regex helpers
  bool _validateName(String name) {
    return RegExp(r'^[A-Za-z\s]+$').hasMatch(name);
  }

  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    return RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      if (_isSignup) {
        // Signup Submit
        if (!_validateName(_nameController.text.trim())) {
          throw Exception("Name should only contain alphabets and spaces.");
        }
        if (!_validatePassword(_passwordController.text)) {
          throw Exception("Password must be at least 8 characters long and contain at least one special character.");
        }

        final res = await ApiService.signup(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (res.statusCode == 201 || res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created! Please login.")),
          );
          setState(() {
            _isSignup = false;
            _passwordController.clear();
          });
        } else {
          final errBody = jsonDecode(res.body);
          throw Exception(errBody['message'] ?? "Signup failed");
        }
      } else {
        // Login Submit
        final res = await ApiService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (res.statusCode == 200) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          final errBody = jsonDecode(res.body);
          throw Exception(errBody['message'] ?? "Login failed");
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email first!")),
      );
      return;
    }
    setState(() {
      _isResetting = true;
    });
  }

  Future<void> _submitReset() async {
    final newPass = _newPasswordController.text;
    if (!_validatePassword(newPass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 8 characters long and contain at least one special character.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiService.resetPassword(
        _emailController.text.trim(),
        newPass,
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset successful! Please login.")),
        );
        setState(() {
          _isResetting = false;
          _newPasswordController.clear();
          _passwordController.clear();
        });
      } else {
        final errBody = jsonDecode(res.body);
        throw Exception(errBody['message'] ?? "Reset failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'NexCall',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'AI Voice Agent Platform',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              // Form Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isResetting 
                            ? 'Reset Password' 
                            : _isSignup ? 'Create Account' : 'Welcome Back',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isResetting 
                            ? 'Enter a new password below'
                            : _isSignup ? 'Start building AI voice agents today' : 'Sign in to your account to continue',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 20),

                        // Error Banner
                        if (_errorMessage.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFEE2E2)),
                            ),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Name Field (Only on signup)
                        if (_isSignup && !_isResetting) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Please enter your name';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.mail_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Please enter email';
                            if (!val.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        if (!_isResetting) ...[
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Please enter password';
                              return null;
                            },
                          ),
                        ],

                        // Forgot password link
                        if (!_isSignup && !_isResetting) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ],

                        // Reset password field
                        if (_isResetting) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Enter new password';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isLoading ? null : _submitReset,
                            child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Reset Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isResetting = false),
                            child: const Text('Back to Login'),
                          ),
                        ],

                        // Submit Button
                        if (!_isResetting) ...[
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _isSignup ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              // Toggle Link
              if (!_isResetting) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignup ? "Already have an account?" : "Don't have an account?",
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignup = !_isSignup;
                          _errorMessage = "";
                        });
                      },
                      child: Text(_isSignup ? 'Sign in' : 'Sign up'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
