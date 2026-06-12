import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import 'box_audit_mode.dart';
import 'reference_history_screen.dart';
import 'two_view_capture_screen.dart';

class BoxAuditEntryScreen extends StatefulWidget {
  const BoxAuditEntryScreen({super.key});

  @override
  State<BoxAuditEntryScreen> createState() => _BoxAuditEntryScreenState();
}

class _BoxAuditEntryScreenState extends State<BoxAuditEntryScreen> {
  final _boxIdController = TextEditingController();
  BoxAuditMode _mode = BoxAuditMode.audit;

  @override
  void dispose() {
    _boxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Box Visual Audit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mode', style: AppTheme.headingSmall),
            const SizedBox(height: 8),
            SegmentedButton<BoxAuditMode>(
              segments: const [
                ButtonSegment(
                  value: BoxAuditMode.reference,
                  label: Text('Reference Capture'),
                  icon: Icon(Icons.bookmark_add_outlined),
                ),
                ButtonSegment(
                  value: BoxAuditMode.audit,
                  label: Text('Audit Capture'),
                  icon: Icon(Icons.fact_check_outlined),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Box / SKU ID', style: AppTheme.headingSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: _openHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _boxIdController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'e.g. BOX-1234 or SKU-001',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _mode == BoxAuditMode.reference
                    ? 'Reference capture is done once per box/SKU. You must capture TWO views:\n'
                          '1) Front-Left 45° corner\n2) Rear-Right 45° corner'
                    : 'Audit capture is done at handover. You must capture the same TWO views.\n'
                          'If severe damage is detected, images + score are sent to the backend and admins are notified.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  _mode == BoxAuditMode.reference
                      ? 'Start Reference Capture'
                      : 'Start Audit Capture',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _start() {
    final boxId = _boxIdController.text.trim();
    if (boxId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Box / SKU ID')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TwoViewCaptureScreen(boxId: boxId, mode: _mode),
      ),
    );
  }

  Future<void> _openHistory() async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ReferenceHistoryScreen()),
    );

    if (selected == null || selected.trim().isEmpty) return;
    _boxIdController.text = selected.trim();
  }
}
