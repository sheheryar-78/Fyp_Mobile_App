import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  bool _isLoading = true;
  List<dynamic> _agents = [];
  List<dynamic> _documents = [];
  String _twilioPhoneNumber = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final agentsRes = await ApiService.getAgents();
      final docsRes = await ApiService.getDocuments();
      final twilioRes = await ApiService.getTwilioConfig();

      if (agentsRes.statusCode == 200) {
        _agents = jsonDecode(agentsRes.body);
      }
      if (docsRes.statusCode == 200) {
        _documents = jsonDecode(docsRes.body);
      }
      if (twilioRes.statusCode == 200) {
        _twilioPhoneNumber = jsonDecode(twilioRes.body)['twilioPhoneNumber'] ?? "";
      }
    } catch (e) {
      debugPrint("Agents fetch error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAgentStatus(Map<String, dynamic> agent, bool newStatusValue) async {
    final originalStatus = agent['status'];
    final updatedStatus = newStatusValue ? 'active' : 'inactive';

    setState(() {
      agent['status'] = updatedStatus;
    });

    try {
      final res = await ApiService.updateAgent(agent['_id'], {
        'status': updatedStatus,
      });

      if (res.statusCode != 200) {
        final errBody = jsonDecode(res.body);
        throw Exception(errBody['message'] ?? "Toggle failed");
      }
    } catch (e) {
      setState(() {
        agent['status'] = originalStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString().replaceAll("Exception: ", "")}")),
      );
    }
  }

  Future<void> _deleteAgent(String id) async {
    try {
      final res = await ApiService.deleteAgent(id);
      if (res.statusCode == 200) {
        setState(() {
          _agents.removeWhere((a) => a['_id'] == id);
        });
        Navigator.pop(context); // Close details sheet if open
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Agent deleted successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete agent: $e")),
      );
    }
  }

  void _showCreateAgentBottomSheet() {
    final nameController = TextEditingController();
    String selectedDocument = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create New AI Agent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Name input
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Agent Name',
                  hintText: 'e.g., Customer Support Agent',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Phone number (read only)
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Assigned Twilio Number',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                controller: TextEditingController(text: _twilioPhoneNumber),
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Document Selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Link Knowledge Base Document',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: "", child: Text("-- None --")),
                  ..._documents.map((doc) {
                    return DropdownMenuItem(
                      value: doc['fileName'] as String,
                      child: Text(doc['fileName'] as String),
                    );
                  }).toList(),
                ],
                onChanged: (val) {
                  selectedDocument = val ?? "";
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
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
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        
                        List<String> docs = [];
                        if (selectedDocument.isNotEmpty) {
                          docs.add(selectedDocument);
                        }

                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);

                        try {
                          final res = await ApiService.createAgent(name, _twilioPhoneNumber, docs);
                          if (res.statusCode == 201 || res.statusCode == 200) {
                            _fetchData();
                          } else {
                            final err = jsonDecode(res.body);
                            throw Exception(err['message'] ?? "Creation failed");
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: ${e.toString().replaceAll("Exception: ", "")}")),
                          );
                          setState(() => _isLoading = false);
                        }
                      },
                      child: const Text('Create', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _showAgentDetailsBottomSheet(Map<String, dynamic> agent) {
    final nameController = TextEditingController(text: agent['name']);
    String selectedDoc = (agent['documents'] != null && agent['documents'].isNotEmpty) 
        ? agent['documents'][0] 
        : "";
    bool isEditing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Text(
                        isEditing ? 'Edit Agent' : agent['name'],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                          // Confirmation
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text("Delete Agent?"),
                              content: const Text("Are you sure you want to delete this agent?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dCtx);
                                    _deleteAgent(agent['_id']);
                                  }, 
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Phone Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PHONE NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                        const SizedBox(height: 4),
                        Text(agent['phoneNumber'] ?? 'No phone assigned', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isEditing) ...[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Agent Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedDoc,
                      decoration: const InputDecoration(labelText: 'Link Knowledge Document', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: "", child: Text("-- None --")),
                        ..._documents.map((doc) => DropdownMenuItem(value: doc['fileName'] as String, child: Text(doc['fileName'] as String))).toList(),
                      ],
                      onChanged: (val) {
                        setModalState(() => selectedDoc = val ?? "");
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        try {
                          final res = await ApiService.updateAgent(agent['_id'], {
                            'name': nameController.text.trim(),
                            'documents': selectedDoc.isNotEmpty ? [selectedDoc] : [],
                          });
                          if (res.statusCode == 200) {
                            _fetchData();
                          }
                        } catch (e) {
                          setState(() => _isLoading = false);
                        }
                      },
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                    ),
                  ] else ...[
                    // Info Row
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Linked Knowledge Doc'),
                      subtitle: Text(
                        (agent['documents'] != null && agent['documents'].isNotEmpty) 
                            ? agent['documents'][0] 
                            : 'No document linked',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.toggle_on_outlined),
                      title: const Text('Current Status'),
                      subtitle: Text((agent['status'] ?? 'inactive').toUpperCase()),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => setModalState(() => isEditing = true),
                      child: const Text('Edit Agent settings'),
                    ),
                  ],
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AI Agents', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/agents'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: _showCreateAgentBottomSheet,
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: _agents.isEmpty 
              ? const Center(child: Text("No agents found. Click + to add."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _agents.length,
                  itemBuilder: (context, index) {
                    final agent = _agents[index];
                    final String name = agent['name'] ?? "AI Agent";
                    final String status = agent['status'] ?? "inactive";
                    final String phone = agent['phoneNumber'] ?? "";
                    final bool isActive = status == "active";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _showAgentDetailsBottomSheet(agent),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.smart_toy_outlined, color: isActive ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        subtitle: Text(phone, style: const TextStyle(fontFamily: 'Courier', fontSize: 13)),
                        trailing: Switch(
                          value: isActive,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (newVal) => _toggleAgentStatus(agent, newVal),
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }
}
