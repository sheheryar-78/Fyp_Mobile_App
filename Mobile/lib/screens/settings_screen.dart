import 'dart:convert';
import 'package:flutter/material';
import '../services/api_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiService.getProfile();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _nameController.text = data['name'] ?? "";
          _emailController.text = data['email'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Profile fetch error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.updateProfile(
        _nameController.text.trim(),
        _emailController.text.trim(),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final cur = _currentPasswordController.text;
    final nxt = _newPasswordController.text;
    if (cur.isEmpty || nxt.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.updatePassword(cur, nxt);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully!")),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
      } else {
        final err = jsonDecode(res.body);
        throw Exception(err['message'] ?? "Password update failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString().replaceAll("Exception: ", "")}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("WARNING: This will permanently delete your account and all associated voice agents and calls. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              setState(() => _isLoading = true);
              try {
                final res = await ApiService.deleteAccount();
                if (res.statusCode == 200) {
                  await ApiService.clearAuth();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Delete account error: $e")),
                );
                setState(() => _isLoading = false);
              }
            },
            child: const Text("Delete Account", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/settings'),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Profile Info
                const Text('Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                          onPressed: _updateProfile,
                          child: const Text('Save Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Security settings
                const Text('Security settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                          onPressed: _changePassword,
                          child: const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 3: Danger Zone
                const Text('Danger Zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Permanently delete your account. This action is irreversible.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: _deleteAccount,
                          child: const Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
    );
  }
}
