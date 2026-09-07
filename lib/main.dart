import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/settings/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(appSettingsProvider.notifier).load();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const PocketDentScannerApp(),
  ));
}
