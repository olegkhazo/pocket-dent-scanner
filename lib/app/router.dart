import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/home/home_screen.dart';
import '../features/light_test/light_test_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
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
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/scan/setup',
        name: 'scan-setup',
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/scan/result/:id',
        name: 'scan-result',
        builder: (context, state) => const Placeholder(),
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
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const Placeholder(),
      ),
    ],
  );
}
