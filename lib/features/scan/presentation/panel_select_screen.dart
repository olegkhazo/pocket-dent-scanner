import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/scan_panel.dart';

class PanelSelectScreen extends StatelessWidget {
  const PanelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: PanelType.values.length,
          itemBuilder: (context, index) {
            final panel = PanelType.values[index];
            return _PanelButton(panel: panel);
          },
        ),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final PanelType panel;

  const _PanelButton({required this.panel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.goNamed(
        'scan',
        queryParameters: {'panel': panel.name},
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(panel.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              panel.displayName,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
