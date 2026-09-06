import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/debug_lab/debug_lab_screen.dart';
import '../features/home/home_screen.dart';
import '../features/light_test/light_test_screen.dart';
import '../features/scan/presentation/panel_select_screen.dart';
import '../features/scan/presentation/scan_processing_screen.dart';
import '../features/scan/presentation/scan_result_screen.dart';
import '../features/scan/presentation/scan_screen.dart';
import '../core/cv/cv_result.dart';
import '../features/instructions/instructions_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/scan/panel',
        name: 'panel-select',
        builder: (context, state) => const PanelSelectScreen(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => ScanScreen(
          panelName: state.uri.queryParameters['panel'] ?? 'other',
        ),
      ),
      GoRoute(
        path: '/scan/processing',
        name: 'scan-processing',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ScanProcessingScreen(
            framePaths:
                (extra['framePaths'] as List?)?.cast<String>() ?? [],
            sessionDir: extra['sessionDir'] as String? ?? '',
            panelName: extra['panel'] as String? ?? 'Unknown',
            durationSeconds: extra['duration'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/scan/result',
        name: 'scan-result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ScanResultScreen(
            result: extra['result'] as CvResult? ?? CvResult.empty,
            sessionDir: extra['sessionDir'] as String? ?? '',
            panelName: extra['panel'] as String? ?? 'Unknown',
            durationSeconds: extra['duration'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/history',
        name: 'scan-history',
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/light-test',
        name: 'light-test',
        builder: (context, state) => const LightTestScreen(),
      ),
      GoRoute(
        path: '/debug-lab',
        name: 'debug-lab',
        builder: (context, state) => DebugLabScreen(
          initialSessionDir: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/instructions',
        name: 'instructions',
        builder: (context, state) => const InstructionsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const Placeholder(),
      ),
    ],
  );
}
