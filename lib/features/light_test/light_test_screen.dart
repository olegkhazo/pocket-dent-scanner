import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/light/light_pattern_notifier.dart';
import '../../core/light/light_pattern_widget.dart';
import 'light_test_controls.dart';

class LightTestScreen extends ConsumerStatefulWidget {
  const LightTestScreen({super.key});

  @override
  ConsumerState<LightTestScreen> createState() => _LightTestScreenState();
}

class _LightTestScreenState extends ConsumerState<LightTestScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pattern = ref.watch(lightPatternProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pattern fills entire screen — the light source.
          LightPatternWidget(pattern: pattern),

          // Back button — minimal, top-right corner.
          Positioned(
            top: 40,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 24),
                onPressed: () => context.pop(),
                tooltip: 'Exit',
              ),
            ),
          ),

          // Controls panel slides up from bottom.
          DraggableScrollableSheet(
            initialChildSize: 0.06,
            minChildSize: 0.06,
            maxChildSize: 0.65,
            snap: true,
            snapSizes: const [0.06, 0.65],
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: const LightTestControls(),
            ),
          ),
        ],
      ),
    );
  }
}
