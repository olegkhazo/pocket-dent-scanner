import 'dart:convert';
import 'dart:io';

class ScanMeta {
  final String id;
  final String panelName;
  final DateTime createdAt;
  final int durationSeconds;
  final int frameCount;
  final int candidateCount;
  final int qualityScore;
  final String qualityLabel;
  final String sessionDir;
  final String? thumbnailPath;

  const ScanMeta({
    required this.id,
    required this.panelName,
    required this.createdAt,
    required this.durationSeconds,
    required this.frameCount,
    required this.candidateCount,
    required this.qualityScore,
    required this.qualityLabel,
    required this.sessionDir,
    this.thumbnailPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'panelName': panelName,
        'createdAt': createdAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'frameCount': frameCount,
        'candidateCount': candidateCount,
        'qualityScore': qualityScore,
        'qualityLabel': qualityLabel,
        'sessionDir': sessionDir,
        'thumbnailPath': thumbnailPath,
      };

  factory ScanMeta.fromJson(Map<String, dynamic> json, String sessionDir) =>
      ScanMeta(
        id: json['id'] as String,
        panelName: json['panelName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        durationSeconds: json['durationSeconds'] as int,
        frameCount: json['frameCount'] as int,
        candidateCount: json['candidateCount'] as int,
        qualityScore: json['qualityScore'] as int,
        qualityLabel: json['qualityLabel'] as String,
        sessionDir: sessionDir,
        thumbnailPath: json['thumbnailPath'] as String?,
      );

  Future<void> saveTo(String dir) async {
    final file = File('$dir/scan_meta.json');
    await file.writeAsString(jsonEncode(toJson()));
  }

  static Future<ScanMeta?> loadFrom(String dir) async {
    try {
      final file = File('$dir/scan_meta.json');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return ScanMeta.fromJson(json, dir);
    } catch (_) {
      return null;
    }
  }
}
