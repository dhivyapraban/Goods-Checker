import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/audit/reference_image_storage.dart';
import 'box_audit_mode.dart';
import 'two_view_capture_screen.dart';

class ReferenceHistoryScreen extends StatefulWidget {
  const ReferenceHistoryScreen({super.key});

  @override
  State<ReferenceHistoryScreen> createState() => _ReferenceHistoryScreenState();
}

class _ReferenceHistoryScreenState extends State<ReferenceHistoryScreen> {
  final _storage = ReferenceImageStorage();
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<ReferenceSummary> _all = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _storage.listReferenceHistory();
      setState(() {
        _all = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reference History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : _buildList(),
    );
  }

  Widget _buildList() {
    final q = _searchController.text.trim().toLowerCase();
    final items = q.isEmpty
        ? _all
        : _all.where((e) => e.boxId.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search Box / SKU ID',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyState(onReload: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      return ListTile(
                        onTap: () => Navigator.pop(context, it.boxId),
                        leading: CircleAvatar(
                          backgroundColor: it.complete
                              ? AppTheme.success.withAlpha(46)
                              : AppTheme.warning.withAlpha(46),
                          child: Icon(
                            it.complete
                                ? Icons.verified_outlined
                                : Icons.pending_outlined,
                            color: it.complete
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                        ),
                        title: Text(it.boxId, style: AppTheme.bodyMedium),
                        subtitle: Text(
                          _subtitle(it),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Start capture',
                              icon: const Icon(Icons.play_circle_outline),
                              onPressed: () => _showActions(it),
                            ),
                            IconButton(
                              tooltip: 'Delete reference',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(it),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showActions(ReferenceSummary it) async {
    final action = await showModalBottomSheet<_HistoryAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(it.boxId, style: AppTheme.bodyMedium),
                subtitle: Text(
                  _subtitle(it),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Start Audit Capture'),
                subtitle: Text(
                  it.complete
                      ? 'Compare against saved reference (A+B)'
                      : 'Needs both reference views first',
                  style: AppTheme.bodySmall.copyWith(
                    color: it.complete
                        ? AppTheme.textSecondary
                        : AppTheme.warning,
                  ),
                ),
                enabled: it.complete,
                onTap: () => Navigator.pop(context, _HistoryAction.audit),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: const Text('Start Reference Capture'),
                subtitle: Text(
                  'Capture/overwrite reference images',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                onTap: () => Navigator.pop(context, _HistoryAction.reference),
              ),
              ListTile(
                leading: const Icon(Icons.input_outlined),
                title: const Text('Use this ID only'),
                subtitle: Text(
                  'Fill in Box/SKU ID and go back',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                onTap: () => Navigator.pop(context, _HistoryAction.useId),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == null) return;

    switch (action) {
      case _HistoryAction.useId:
        if (!mounted) return;
        Navigator.pop(context, it.boxId);
        return;
      case _HistoryAction.audit:
        await _startCapture(it.boxId, BoxAuditMode.audit);
        return;
      case _HistoryAction.reference:
        await _startCapture(it.boxId, BoxAuditMode.reference);
        return;
    }
  }

  Future<void> _startCapture(String boxId, BoxAuditMode mode) async {
    // Replace history so Back returns to entry.
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TwoViewCaptureScreen(boxId: boxId, mode: mode),
      ),
    );
  }

  String _subtitle(ReferenceSummary it) {
    final a = it.hasA ? 'A✓' : 'A–';
    final b = it.hasB ? 'B✓' : 'B–';
    final ts = it.updatedAt == null
        ? ''
        : ' • ${it.updatedAt!.toLocal().toString().split('.').first}';
    return 'Views: $a  $b$ts';
  }

  Future<void> _confirmDelete(ReferenceSummary it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reference?'),
        content: Text(
          'This removes saved reference images for:\n\n${it.boxId}\n\nAudit will not work for this ID until you capture reference again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _storage.deleteReference(it.boxId);
    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted reference for ${it.boxId}')),
    );
  }
}

enum _HistoryAction { audit, reference, useId }

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onReload;

  const _EmptyState({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 44, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text('No references yet', style: AppTheme.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Run Reference Capture once per box/SKU to save it here.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => onReload(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 44, color: AppTheme.error),
            const SizedBox(height: 12),
            Text('Failed to load history', style: AppTheme.headingSmall),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
