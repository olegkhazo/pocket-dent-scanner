import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'scan_meta.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  late Future<List<ScanMeta>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHistory();
  }

  Future<List<ScanMeta>> _loadHistory() async {
    final base = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${base.path}/scans');
    if (!await scansDir.exists()) return [];

    final metas = <ScanMeta>[];
    await for (final entry in scansDir.list()) {
      if (entry is! Directory) continue;
      final meta = await ScanMeta.loadFrom(entry.path);
      if (meta != null) metas.add(meta);
    }

    metas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return metas;
  }

  Future<void> _delete(ScanMeta meta) async {
    await Directory(meta.sessionDir).delete(recursive: true);
    setState(() {
      _future = _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<ScanMeta>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 56, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No scans yet',
                      style: TextStyle(color: Colors.white54, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Tap New Scan on the home screen to start.',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _ScanCard(
              meta: items[i],
              onDelete: () => _delete(items[i]),
              onOpen: () => context.pushNamed('debug-lab',
                  extra: items[i].sessionDir),
            ),
          );
        },
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final ScanMeta meta;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _ScanCard({
    required this.meta,
    required this.onDelete,
    required this.onOpen,
  });

  Color get _qualityColor {
    if (meta.qualityScore >= 80) return Colors.greenAccent;
    if (meta.qualityScore >= 60) return Colors.lightGreenAccent;
    if (meta.qualityScore >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String get _dateLabel {
    final d = meta.createdAt;
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(meta.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete scan?'),
            content: const Text('This will permanently delete the scan and all frames.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              // Thumbnail.
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: meta.thumbnailPath != null && File(meta.thumbnailPath!).existsSync()
                    ? Image.file(File(meta.thumbnailPath!),
                        width: 80, height: 80, fit: BoxFit.cover)
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.white10,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: Colors.white24),
                      ),
              ),
              const SizedBox(width: 12),
              // Info.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta.panelName,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_dateLabel,
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.adjust, size: 14,
                              color: meta.candidateCount > 0
                                  ? Colors.orangeAccent
                                  : Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            meta.candidateCount == 0
                                ? 'No candidates'
                                : '${meta.candidateCount} candidate${meta.candidateCount == 1 ? '' : 's'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Quality badge.
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Text(
                      '${meta.qualityScore}',
                      style: TextStyle(
                          color: _qualityColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(meta.qualityLabel,
                        style: TextStyle(color: _qualityColor, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
