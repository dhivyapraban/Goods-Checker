import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/audit_damage_result.dart';
import '../../services/audit/audit_damage_service.dart';
import '../../services/audit/reference_image_storage.dart';
import '../../services/vision/image_quality_validator.dart';
import '../../widgets/audit/camera_overlay_guide.dart';
import 'box_audit_mode.dart';

class TwoViewCaptureScreen extends StatefulWidget {
  final String boxId;
  final BoxAuditMode mode;

  const TwoViewCaptureScreen({
    super.key,
    required this.boxId,
    required this.mode,
  });

  @override
  State<TwoViewCaptureScreen> createState() => _TwoViewCaptureScreenState();
}

class _TwoViewCaptureScreenState extends State<TwoViewCaptureScreen> {
  CameraController? _camera;
  bool _initializing = true;
  String? _initError;

  int _step = 0; // 0 => viewA, 1 => viewB

  Uint8List? _capturedBytes;
  ImageQualityResult? _validation;

  Uint8List? _viewA;
  Uint8List? _viewB;

  AuditDamageResult? _result;
  bool _auditing = false;

  final _refStorage = ReferenceImageStorage();
  final _auditService = AuditDamageService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _initializing = true;
      _initError = null;
    });

    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      setState(() {
        _camera = controller;
        _initializing = false;
      });

      if (widget.mode == BoxAuditMode.audit) {
        final ref = await _refStorage.getReference(widget.boxId);
        if (ref == null || !ref.complete) {
          if (mounted) {
            _showBlockingError(
              'Missing reference',
              'No reference images found for ${widget.boxId}.\n\nRun Reference Capture first.',
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _initError = e.toString();
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _step == 0 ? 'Front-Left 45° View' : 'Rear-Right 45° View';
    final subtitle = widget.mode == BoxAuditMode.reference
        ? 'REFERENCE CAPTURE • ${widget.boxId}'
        : 'AUDIT CAPTURE • ${widget.boxId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == BoxAuditMode.reference
              ? 'Reference Capture'
              : 'Audit Capture',
        ),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _initError != null
          ? _ErrorView(message: _initError!, onRetry: _init)
          : _buildContent(title, subtitle),
    );
  }

  Widget _buildContent(String title, String subtitle) {
    // If we have a captured image, show review screen.
    if (_capturedBytes != null) {
      final failures = _validation?.failures ?? const <ImageQualityFailure>[];
      final ok = _validation?.ok ?? false;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_capturedBytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            if (!ok)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retake required',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final f in failures)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${f.message}',
                          style: AppTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.35)),
                ),
                child: Text(
                  'Validation passed. Ready to continue.',
                  style: AppTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retake,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: ok ? _accept : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Use Photo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Result screen after audit.
    if (_result != null) {
      final r = _result!;
      final severityLabel = _labelForDamage(r.damagePercent);
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Audit Result', style: AppTheme.headingLarge),
            const SizedBox(height: 12),
            _MetricRow(
              label: 'Damage %',
              value: '${r.damagePercent.toStringAsFixed(1)}%',
            ),
            _MetricRow(
              label: 'Confidence',
              value: r.confidence.toStringAsFixed(2),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (r.severeDamage ? AppTheme.error : AppTheme.info)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (r.severeDamage ? AppTheme.error : AppTheme.info)
                      .withOpacity(0.35),
                ),
              ),
              child: Text(
                severityLabel,
                style: AppTheme.headingSmall.copyWith(
                  color: r.severeDamage ? AppTheme.error : AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            if (r.reason.isNotEmpty)
              Text(
                r.reason,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            if (r.escalatedToAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Admin notified (severe damage).',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _auditing
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    }

    // Live camera capture.
    final controller = _camera!;
    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(controller)),
        Positioned.fill(
          child: CameraOverlayGuide(title: title, subtitle: subtitle),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.value.isTakingPicture ? null : _capture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _capture() async {
    final controller = _camera;
    if (controller == null) return;

    try {
      final file = await controller.takePicture();
      final bytes = await File(file.path).readAsBytes();

      final validation = ImageQualityValidator.validate(bytes);
      if (!validation.ok) {
        setState(() {
          _capturedBytes = bytes;
          _validation = validation;
        });
        return;
      }

      // Don't proceed until the user confirms the validated image.
      setState(() {
        _capturedBytes = bytes;
        _validation = validation;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  void _retake() {
    setState(() {
      _capturedBytes = null;
      _validation = null;
    });
  }

  Future<void> _accept() async {
    final bytes = _capturedBytes;
    if (bytes == null) {
      debugPrint('_accept: bytes is null, returning early');
      return;
    }

    debugPrint(
      '_accept: step=$_step, mode=${widget.mode}, bytes.length=${bytes.length}',
    );

    try {
      if (_step == 0) {
        _viewA = bytes;
        debugPrint('_accept: saved viewA');
      } else {
        _viewB = bytes;
        debugPrint('_accept: saved viewB');
      }

      // Reference flow: store and move on.
      if (widget.mode == BoxAuditMode.reference) {
        debugPrint('_accept: reference mode, step=$_step');
        if (_step == 0) {
          debugPrint('_accept: saving reference view A');
          await _refStorage.saveReferenceView(
            boxId: widget.boxId,
            step: 0,
            imageBytes: bytes,
          );
          debugPrint('_accept: reference view A saved, moving to step 1');
        } else {
          debugPrint('_accept: saving reference view B');
          await _refStorage.saveReferenceView(
            boxId: widget.boxId,
            step: 1,
            imageBytes: bytes,
          );
          debugPrint('_accept: reference view B saved, showing result');
        }

        setState(() {
          _capturedBytes = null;
          _validation = null;

          if (_step == 0) {
            _step = 1;
            debugPrint('_accept: step changed to 1');
          } else {
            _result = const AuditDamageResult(
              severeDamage: false,
              damagePercent: 0,
              confidence: 1,
              reason: 'Reference saved',
              escalatedToAdmin: false,
            );
            debugPrint('_accept: result set to Reference saved');
          }
        });

        return;
      }

      // Audit flow: after both views captured, compare.
      if (_step == 0) {
        debugPrint('_accept: audit mode, step 0 -> moving to step 1');
        setState(() {
          _capturedBytes = null;
          _validation = null;
          _step = 1;
        });
        return;
      }

      debugPrint('_accept: audit mode, step 1 - starting API call');
      debugPrint('_accept: viewA=${_viewA?.length}, viewB=${_viewB?.length}');

      final refs = await _refStorage.getReference(widget.boxId);
      debugPrint('_accept: refs loaded, complete=${refs?.complete}');
      if (refs == null || !refs.complete || _viewA == null || _viewB == null) {
        if (!mounted) return;
        _showBlockingError(
          'Missing reference',
          'Reference images not found. Run Reference Capture first.',
        );
        return;
      }

      final refABytes = await refs.readABytes();
      final refBBytes = await refs.readBBytes();
      if (refABytes == null || refBBytes == null) {
        if (!mounted) return;
        _showBlockingError(
          'Missing reference',
          'Saved reference files are missing. Please re-capture reference images.',
        );
        return;
      }

      setState(() {
        _capturedBytes = null;
        _validation = null;
        _auditing = true;
      });

      debugPrint('_accept: calling auditDamage API...');
      try {
        final result = await _auditService.auditDamage(
          boxId: widget.boxId,
          refViewA: refABytes,
          refViewB: refBBytes,
          curViewA: _viewA!,
          curViewB: _viewB!,
        );

        debugPrint('_accept: API returned result: ${result.damagePercent}%');
        if (!mounted) return;
        setState(() {
          _result = result;
          _auditing = false;
        });
      } catch (e) {
        debugPrint('Audit service error: $e');
        if (!mounted) return;
        // Show error as a result so user sees it on the result screen.
        setState(() {
          _result = AuditDamageResult(
            severeDamage: false,
            damagePercent: 0,
            confidence: 0,
            reason: 'Audit failed: $e',
            escalatedToAdmin: false,
          );
          _auditing = false;
        });
      }
    } catch (e) {
      debugPrint('_accept outer error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Processing failed: $e')));
    }
  }

  String _labelForDamage(double damagePercent) {
    if (damagePercent < 15) return 'Intact';
    if (damagePercent < 30) return 'Minor damage';
    if (damagePercent < 35) return 'Moderate damage';
    return 'Severe damage';
  }

  Future<void> _showBlockingError(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
            const SizedBox(height: 12),
            Text('Camera init failed', style: AppTheme.headingSmall),
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

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          Text(value, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
}
