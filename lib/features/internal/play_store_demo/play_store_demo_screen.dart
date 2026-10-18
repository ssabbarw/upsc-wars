import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'play_store_demo_caption.dart';
import 'play_store_demo_scenes.dart';
import 'play_store_demo_script.dart';

/// Debug-only promo walkthrough for Play Store screen recording.
///
/// Auto-plays every beat using its scripted duration — no tap/swipe needed.
/// System back exits.
class PlayStoreDemoScreen extends HookWidget {
  const PlayStoreDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('Not available')));
    }

    final stepIndex = useState(0);
    final finished = useState(false);

    final step =
        playStoreDemoScript[stepIndex.value.clamp(
          0,
          playStoreDemoScript.length - 1,
        )];
    final isLast = stepIndex.value >= playStoreDemoScript.length - 1;

    // Auto-advance through the script. Stays on the end card.
    useEffect(() {
      if (finished.value || isLast) {
        finished.value = true;
        return null;
      }
      final duration = playStoreDemoScript[stepIndex.value].duration;
      final timer = Timer(duration, () {
        stepIndex.value = stepIndex.value + 1;
        finished.value = false;
      });
      return timer.cancel;
    }, [stepIndex.value, finished.value]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(step.beat),
                child: PlayStoreDemoScene(beat: step.beat),
              ),
            ),
            PlayStoreDemoCaptionOverlay(step: step),
          ],
        ),
      ),
    );
  }
}
