import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nexcall_app_bar.dart';
import '../widgets/shimmer_loaders.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/app_snackbar.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading    = true;
  bool _hasError     = false;
  bool _isUploading  = false;
  List<dynamic> _documents = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final res = await ApiService.getDocuments();
      if (res.statusCode == 200 && mounted) {
        setState(() => _documents = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Docs load error: $e');
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_documents.any((d) => d['status'] == 'processing')) {
        _load();
      }
    });
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
      );
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      setState(() => _isUploading = true);

      final streamed = await ApiService.uploadDocument(filePath, fileName);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) AppSnackBar.success(context, 'Document uploaded successfully!');
        _load();
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _delete(String id) async {
    try {
      final res = await ApiService.deleteDocument(id);
      if (res.statusCode == 200) {
        setState(() => _documents.removeWhere((d) => d['_id'] == id));
        if (mounted) AppSnackBar.success(context, 'Document deleted');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Failed to delete document');
    }
  }

  void _showDeleteDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text(
            '"$name" will be permanently deleted and unlinked from all agents.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              _delete(id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Download ───────────────────────────────────────────────────────────────

  Future<void> _download(String id) async {
    final url = Uri.parse(ApiService.getDownloadUrl(id));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) AppSnackBar.error(context, 'Could not open download link');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const NexCallAppBar(title: 'Documents'),
      body: _isLoading
          ? const ShimmerListView(count: 4)
          : _hasError
              ? ErrorStateWidget(
                  message: 'Failed to load documents. Check your connection.',
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryBlue,
                  child: Column(
                    children: [
                      // ── Upload Zone ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _isUploading
                            ? _UploadProgressCard()
                            : _UploadZone(onTap: _pickAndUpload, isDark: isDark),
                      ),

                      // ── Header ──
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Uploaded Documents',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            if (_documents.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlueXLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_documents.length}',
                                  style: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── List ──
                      Expanded(
                        child: _documents.isEmpty
                            ? EmptyStateWidget(
                                icon: Icons.cloud_upload_outlined,
                                title: 'No Documents Yet',
                                subtitle:
                                    'Upload PDF, DOCX, or TXT files to power your AI agents with knowledge.',
                                actionLabel: 'Upload Document',
                                onAction: _pickAndUpload,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 32),
                                itemCount: _documents.length,
                                itemBuilder: (context, i) {
                                  final doc      = _documents[i];
                                  final fileName = doc['fileName'] ?? 'File';
                                  final status   = doc['status']   ?? 'processing';
                                  final size     = doc['size']     ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _DocumentCard(
                                      fileName: fileName,
                                      status: status,
                                      size: size,
                                      onDownload: () => _download(doc['_id']),
                                      onDelete: () =>
                                          _showDeleteDialog(doc['_id'], fileName),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Upload Zone ───────────────────────────────────────────────────────────────

class _UploadZone extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _UploadZone({required this.onTap, required this.isDark});

  @override
  State<_UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends State<_UploadZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bounce = Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovering = true),
      onTapUp: (_) => setState(() => _hovering = false),
      onTapCancel: () => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: _hovering
              ? (isDark ? AppTheme.darkCard : AppTheme.primaryBlueXLight)
              : (isDark ? AppTheme.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovering
                ? AppTheme.primaryBlue
                : AppTheme.primaryBlueBorder,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _bounce.value),
                child: child,
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueXLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload_outlined,
                    color: AppTheme.primaryBlue, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload Knowledge Base Document',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'PDF, DOCX or TXT  ·  Max 10 MB',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueXLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlueBorder),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: AppTheme.primaryBlue, strokeWidth: 2.5),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Uploading document…',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue)),
                SizedBox(height: 2),
                Text('This may take a moment',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Document Card ─────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final String fileName;
  final String status;
  final String size;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.fileName,
    required this.status,
    required this.size,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeFg;
    Widget? statusIndicator;

    switch (status) {
      case 'vectorized':
        badgeBg = AppTheme.successGreenLight;
        badgeFg = AppTheme.successGreenDark;
        statusIndicator = null;
        break;
      case 'failed':
        badgeBg = AppTheme.errorRedLight;
        badgeFg = AppTheme.errorRed;
        statusIndicator = null;
        break;
      default: // processing
        badgeBg = AppTheme.warningAmberLight;
        badgeFg = AppTheme.warningAmberDark;
        statusIndicator = const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: AppTheme.warningAmber),
        );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueXLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_rounded,
                      color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fileName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (size.isNotEmpty)
                        Text(size,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (statusIndicator != null) ...[
                        statusIndicator,
                        const SizedBox(width: 5),
                      ],
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                            color: badgeFg,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  icon: Icons.download_rounded,
                  label: 'Download',
                  onTap: onDownload,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  onTap: onDelete,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: c),
      label: Text(label, style: TextStyle(fontSize: 12, color: c)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
