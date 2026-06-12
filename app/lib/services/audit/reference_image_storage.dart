import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage_service.dart';

class BoxReferenceImages {
  final String? viewAPath;
  final String? viewBPath;

  const BoxReferenceImages({required this.viewAPath, required this.viewBPath});

  bool get hasA => viewAPath != null && viewAPath!.isNotEmpty;
  bool get hasB => viewBPath != null && viewBPath!.isNotEmpty;
  bool get complete => hasA && hasB;

  Future<Uint8List?> readABytes() async {
    if (!hasA) return null;
    final f = File(viewAPath!);
    if (!await f.exists()) return null;
    return f.readAsBytes();
  }

  Future<Uint8List?> readBBytes() async {
    if (!hasB) return null;
    final f = File(viewBPath!);
    if (!await f.exists()) return null;
    return f.readAsBytes();
  }
}

class ReferenceSummary {
  final String boxId;
  final bool hasA;
  final bool hasB;
  final DateTime? updatedAt;

  const ReferenceSummary({
    required this.boxId,
    required this.hasA,
    required this.hasB,
    required this.updatedAt,
  });

  bool get complete => hasA && hasB;
}

class ReferenceImageStorage {
  ReferenceImageStorage({StorageService? storageService})
    : _storageService = storageService ?? StorageService();

  final StorageService _storageService;

  static const String _prefix = 'box_ref_images:';
  static String _key(String boxId) => '$_prefix$boxId';

  Future<Directory> _rootDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(dir.path, 'box_refs'));
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<String> _writeViewFile({
    required String boxId,
    required String view,
    required Uint8List bytes,
  }) async {
    final root = await _rootDir();
    final boxDir = Directory(p.join(root.path, boxId));
    if (!await boxDir.exists()) await boxDir.create(recursive: true);

    final filePath = p.join(boxDir.path, '$view.jpg');
    final f = File(filePath);
    await f.writeAsBytes(bytes, flush: true);
    return filePath;
  }

  Future<void> saveReferenceView({
    required String boxId,
    required int step,
    required Uint8List imageBytes,
  }) async {
    if (step != 0 && step != 1) {
      throw ArgumentError.value(step, 'step', 'Must be 0 (A) or 1 (B)');
    }

    final raw = await _storageService.getValue(_key(boxId));
    Map<String, dynamic> payload;
    if (raw != null && raw.isNotEmpty) {
      try {
        payload = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        payload = <String, dynamic>{};
      }
    } else {
      payload = <String, dynamic>{};
    }

    if (step == 0) {
      payload['viewAPath'] = await _writeViewFile(
        boxId: boxId,
        view: 'ref_view_A',
        bytes: imageBytes,
      );
    } else {
      payload['viewBPath'] = await _writeViewFile(
        boxId: boxId,
        view: 'ref_view_B',
        bytes: imageBytes,
      );
    }

    payload['updatedAt'] = DateTime.now().toIso8601String();

    await _storageService.saveValue(_key(boxId), jsonEncode(payload));
  }

  Future<BoxReferenceImages?> getReference(String boxId) async {
    final raw = await _storageService.getValue(_key(boxId));
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final a = map['viewAPath'] is String ? map['viewAPath'] as String : null;
      final b = map['viewBPath'] is String ? map['viewBPath'] as String : null;
      return BoxReferenceImages(viewAPath: a, viewBPath: b);
    } catch (_) {
      return null;
    }
  }

  Future<List<ReferenceSummary>> listReferenceHistory() async {
    final keys = await _storageService.getKeys();
    final refKeys = keys.where((k) => k.startsWith(_prefix)).toList();

    final out = <ReferenceSummary>[];
    for (final k in refKeys) {
      final boxId = k.substring(_prefix.length);
      final raw = await _storageService.getValue(k);
      if (raw == null || raw.isEmpty) continue;

      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final hasA =
            map['viewAPath'] is String &&
            (map['viewAPath'] as String).isNotEmpty;
        final hasB =
            map['viewBPath'] is String &&
            (map['viewBPath'] as String).isNotEmpty;
        final updatedAt = map['updatedAt'] is String
            ? DateTime.tryParse(map['updatedAt'] as String)
            : null;
        out.add(
          ReferenceSummary(
            boxId: boxId,
            hasA: hasA,
            hasB: hasB,
            updatedAt: updatedAt,
          ),
        );
      } catch (_) {
        // Skip corrupt entries.
      }
    }

    out.sort((a, b) {
      final ad = a.updatedAt;
      final bd = b.updatedAt;
      if (ad != null && bd != null) return bd.compareTo(ad);
      if (ad != null) return -1;
      if (bd != null) return 1;
      return a.boxId.toLowerCase().compareTo(b.boxId.toLowerCase());
    });

    return out;
  }

  Future<void> deleteReference(String boxId) async {
    // Best-effort: delete files then metadata.
    try {
      final root = await _rootDir();
      final dir = Directory(p.join(root.path, boxId));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}

    await _storageService.deleteValue(_key(boxId));
  }
}
