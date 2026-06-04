import 'dart:convert';
import 'dart:async';
import 'package:flutter/material';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../main.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = true;
  List<dynamic> _documents = [];
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
    _startPolling();
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDocuments() async {
    try {
      final res = await ApiService.getDocuments();
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _documents = jsonDecode(res.body);
          });
        }
      }
    } catch (e) {
      debugPrint("Docs fetch error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Poll for "processing" status files
  void _startPolling() {
    _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final hasProcessing = _documents.any((doc) => doc['status'] == 'processing');
      if (hasProcessing) {
        _fetchDocuments();
      }
    });
  }

  Future<void> _pickAndUploadFile() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      setState(() {
        _isLoading = true;
      });

      // Upload
      final streamedResponse = await ApiService.uploadDocument(filePath, fileName);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document uploaded successfully!")),
        );
        _fetchDocuments();
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? "Upload failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload error: ${e.toString().replaceAll("Exception: ", "")}")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDocument(String id) async {
    try {
      final res = await ApiService.deleteDocument(id);
      if (res.statusCode == 200) {
        setState(() {
          _documents.removeWhere((doc) => doc['_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document deleted")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete error: $e")),
      );
    }
  }

  Future<void> _downloadDocument(String id) async {
    final downloadUrl = Uri.parse(ApiService.getDownloadUrl(id));
    if (await canLaunchUrl(downloadUrl)) {
      await launchUrl(downloadUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download document")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/documents'),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Dash upload header box
              GestureDetector(
                onTap: _pickAndUploadFile,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6),
                      width: 1.5,
                      style: BorderStyle.solid, // Flat solid borders represent high-quality container actions
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload Knowledge Base Documents',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap here to browse PDF, DOCX, or TXT (Max 10MB)',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Uploaded Documents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ),

              // Documents List
              Expanded(
                child: _documents.isEmpty
                  ? const Center(child: Text("No documents linked. Upload one to start."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        final String fileName = doc['fileName'] ?? "Doc File";
                        final String status = doc['status'] ?? "processing";
                        final String size = doc['size'] ?? "0 KB";
                        
                        Color badgeColor = Colors.orange;
                        Color textBadgeColor = Colors.white;
                        if (status == "vectorized") {
                          badgeColor = const Color(0xFFD1FAE5);
                          textBadgeColor = const Color(0xFF065F46);
                        } else if (status == "failed") {
                          badgeColor = const Color(0xFFFEE2E2);
                          textBadgeColor = const Color(0xFF991B1B);
                        } else {
                          badgeColor = const Color(0xFFFEF3C7);
                          textBadgeColor = const Color(0xFF92400E);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.description, color: Color(0xFF2563EB)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(size, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(color: textBadgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.download, color: Color(0xFF64748B)),
                                      onPressed: () => _downloadDocument(doc['_id']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _deleteDocument(doc['_id']),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}
import 'package:http/http.dart' as http;
