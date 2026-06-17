import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nexcall_app_bar.dart';
import '../widgets/shimmer_loaders.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/app_snackbar.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  bool _isLoading    = true;
  bool _hasError     = false;
  List<dynamic> _agents    = [];
  List<dynamic> _documents = [];
  String _twilioPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final results = await Future.wait([
        ApiService.getAgents(),
        ApiService.getDocuments(),
        ApiService.getTwilioConfig(),
      ]);
      if (results[0].statusCode == 200) _agents    = jsonDecode(results[0].body);
      if (results[1].statusCode == 200) _documents = jsonDecode(results[1].body);
      if (results[2].statusCode == 200) {
        _twilioPhoneNumber = jsonDecode(results[2].body)['twilioPhoneNumber'] ?? '';
      }
    } catch (e) {
      debugPrint('Agents load error: $e');
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Toggle Agent Status ────────────────────────────────────────────────────

  Future<void> _toggleAgent(Map<String, dynamic> agent, bool newVal) async {
    final original = agent['status'] as String?;
    final updated  = newVal ? 'active' : 'inactive';
    setState(() => agent['status'] = updated);
    try {
      final res = await ApiService.updateAgent(agent['_id'], {'status': updated});
      if (res.statusCode != 200) {
        final err = jsonDecode(res.body);
        throw Exception(err['message'] ?? 'Toggle failed');
      }
    } catch (e) {
      setState(() => agent['status'] = original);
      if (mounted) {
        AppSnackBar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // ── Delete Agent ───────────────────────────────────────────────────────────

  Future<void> _deleteAgent(String id) async {
    try {
      final res = await ApiService.deleteAgent(id);
      if (res.statusCode == 200) {
        setState(() => _agents.removeWhere((a) => a['_id'] == id));
        if (mounted) {
          Navigator.pop(context);
          AppSnackBar.success(context, 'Agent deleted successfully');
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed to delete agent');
    }
  }

  // ── Create Agent Sheet ─────────────────────────────────────────────────────

  void _showCreateSheet() {
    final nameCtrl = TextEditingController();
    String selectedDoc = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('New AI Agent',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Configure your AI voice agent settings',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),

              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Agent Name',
                  hintText: 'e.g., Customer Support Agent',
                  prefixIcon: Icon(Icons.smart_toy_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                readOnly: true,
                controller: TextEditingController(text: _twilioPhoneNumber),
                decoration: const InputDecoration(
                  labelText: 'Assigned Twilio Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: selectedDoc.isEmpty ? null : selectedDoc,
                decoration: const InputDecoration(
                  labelText: 'Link Knowledge Document',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                hint: const Text('-- None --'),
                items: _documents.map<DropdownMenuItem<String>>((doc) {
                  return DropdownMenuItem(
                    value: doc['fileName'] as String,
                    child: Text(doc['fileName'] as String,
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setSheet(() => selectedDoc = val ?? ''),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        try {
                          final docs = selectedDoc.isNotEmpty ? [selectedDoc] : <String>[];
                          final res  = await ApiService.createAgent(name, _twilioPhoneNumber, docs);
                          if (res.statusCode == 201 || res.statusCode == 200) {
                            _load();
                          } else {
                            final err = jsonDecode(res.body);
                            throw Exception(err['message'] ?? 'Creation failed');
                          }
                        } catch (e) {
                          setState(() => _isLoading = false);
                          if (mounted) {
                            AppSnackBar.error(context,
                                e.toString().replaceAll('Exception: ', ''));
                          }
                        }
                      },
                      child: const Text('Create Agent'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Agent Details Sheet ────────────────────────────────────────────────────

  void _showDetailsSheet(Map<String, dynamic> agent) {
    final nameCtrl  = TextEditingController(text: agent['name']);
    String selDoc   = (agent['documents'] != null && (agent['documents'] as List).isNotEmpty)
        ? agent['documents'][0] as String
        : '';
    bool isEditing  = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Agent' : (agent['name'] ?? 'Agent'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDeleteDialog(agent['_id']);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone number chip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlueXLight, Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryBlueBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded,
                        color: AppTheme.primaryBlue, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TWILIO NUMBER',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(
                          agent['phoneNumber'] ?? 'No phone assigned',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlueDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (isEditing) ...[
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Agent Name',
                    prefixIcon: Icon(Icons.smart_toy_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selDoc.isEmpty ? null : selDoc,
                  decoration: const InputDecoration(
                    labelText: 'Knowledge Document',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  hint: const Text('-- None --'),
                  items: _documents.map<DropdownMenuItem<String>>((doc) {
                    return DropdownMenuItem(
                      value: doc['fileName'] as String,
                      child: Text(doc['fileName'] as String,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setSheet(() => selDoc = val ?? ''),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setSheet(() => isEditing = false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);
                          try {
                            await ApiService.updateAgent(agent['_id'], {
                              'name': nameCtrl.text.trim(),
                              'documents': selDoc.isNotEmpty ? [selDoc] : [],
                            });
                            _load();
                          } catch (_) {
                            setState(() => _isLoading = false);
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _InfoRow(
                  icon: Icons.description_outlined,
                  label: 'Linked Document',
                  value: (agent['documents'] != null &&
                          (agent['documents'] as List).isNotEmpty)
                      ? agent['documents'][0]
                      : 'No document linked',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.circle,
                  label: 'Status',
                  value: (agent['status'] ?? 'inactive').toUpperCase(),
                  valueColor: agent['status'] == 'active'
                      ? AppTheme.successGreen
                      : AppTheme.textSecondary,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Agent'),
                  onPressed: () => setSheet(() => isEditing = true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Agent?'),
        content: const Text(
            'This agent and all associated configuration will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              _deleteAgent(id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NexCallAppBar(title: 'AI Agents'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Agent', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const ShimmerListView(count: 4)
          : _hasError
              ? ErrorStateWidget(
                  message: 'Failed to load agents. Check your connection.',
                  onRetry: _load,
                )
              : _agents.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.smart_toy_outlined,
                      title: 'No AI Agents Yet',
                      subtitle:
                          'Create your first AI voice agent to start handling calls automatically.',
                      actionLabel: 'Create Agent',
                      onAction: _showCreateSheet,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primaryBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _agents.length,
                        itemBuilder: (context, index) {
                          final agent   = _agents[index];
                          final name    = agent['name']        ?? 'AI Agent';
                          final status  = agent['status']      ?? 'inactive';
                          final phone   = agent['phoneNumber'] ?? '';
                          final isActive = status == 'active';
                          final docCount = (agent['documents'] as List?)?.length ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: InkWell(
                                onTap: () => _showDetailsSheet(agent),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Status icon
                                      Stack(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? AppTheme.successGreenLight
                                                  : AppTheme.dividerLight,
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              Icons.smart_toy_rounded,
                                              color: isActive
                                                  ? AppTheme.successGreen
                                                  : AppTheme.textSecondary,
                                              size: 24,
                                            ),
                                          ),
                                          if (isActive)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successGreen,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white, width: 2),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15)),
                                            const SizedBox(height: 2),
                                            Text(phone,
                                                style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondary)),
                                            if (docCount > 0) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.description_outlined,
                                                    size: 11,
                                                    color: AppTheme.textTertiary,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '$docCount doc${docCount > 1 ? 's' : ''} linked',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme.textTertiary),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Toggle
                                      Switch(
                                        value: isActive,
                                        onChanged: (val) => _toggleAgent(agent, val),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: valueColor)),
          ],
        ),
      ],
    );
  }
}
