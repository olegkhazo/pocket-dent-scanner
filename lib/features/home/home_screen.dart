import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Dent Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed('settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'PDR Dent Scanner',
                style: TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: () => context.pushNamed('panel-select'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('New Scan', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),
              _NavButton(
                label: 'Light Test',
                icon: Icons.light_mode_outlined,
                onPressed: () => context.pushNamed('light-test'),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: 'CV Debug Lab',
                icon: Icons.biotech_outlined,
                onPressed: () => context.pushNamed('debug-lab'),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: 'How to Scan',
                icon: Icons.menu_book_outlined,
                onPressed: () => context.pushNamed('instructions'),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: 'Scan History',
                icon: Icons.history,
                onPressed: () => context.pushNamed('scan-history'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        side: BorderSide(color: Colors.white12),
      ),
    );
  }
}
