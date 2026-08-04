import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_text_styles.dart';
import 'play_store_demo_caption.dart';
import 'play_store_demo_scenes.dart';
import 'play_store_demo_script.dart';

/// Debug-only auto-play promo for Play Store screen recording.
///
/// Open from Settings → Internal → Play Store demo, start OS screen recording,
/// then tap Play. Tap once to pause/resume; back exits.
class PlayStoreDemoScreen extends HookWidget {
  const PlayStoreDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Not available')),
      );
    }

    final stepIndex = useState(0);
    final playing = useState(false);
    final finished = useState(false);
    final showChrome = useState(true);
    final timerRef = useRef<Timer?>(null);

    void clearTimer() {
      timerRef.value?.cancel();
      timerRef.value = null;
    }

    void scheduleAdvance() {
      clearTimer();
      if (!playing.value || finished.value) return;
      final i = stepIndex.value;
      if (i >= playStoreDemoScript.length) return;
      final step = playStoreDemoScript[i];
      timerRef.value = Timer(step.duration, () {
        if (!context.mounted) return;
        if (i + 1 >= playStoreDemoScript.length) {
          finished.value = true;
          playing.value = false;
          showChrome.value = true;
          return;
        }
        stepIndex.value = i + 1;
        // Hide chrome after the ready beat so the recording stays clean.
        if (playStoreDemoScript[i + 1].beat != PlayStoreDemoBeat.ready) {
          showChrome.value = false;
        }
        scheduleAdvance();
      });
    }

    useEffect(() {
      return clearTimer;
    }, const []);

    void startOrResume() {
      if (finished.value) {
        stepIndex.value = 0;
        finished.value = false;
      }
      playing.value = true;
      if (stepIndex.value > 0) {
        showChrome.value = false;
      }
      scheduleAdvance();
    }

    void pause() {
      playing.value = false;
      clearTimer();
      showChrome.value = true;
    }

    void onTap() {
      if (!playing.value) {
        startOrResume();
      } else {
        pause();
      }
    }

    final step = playStoreDemoScript[stepIndex.value.clamp(
      0,
      playStoreDemoScript.length - 1,
    )];
    final progress = (stepIndex.value + 1) / playStoreDemoScript.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(step.beat),
                  child: PlayStoreDemoScene(beat: step.beat),
                ),
              ),
              // Beat-specific captions while recording (chrome hidden).
              if (!showChrome.value) PlayStoreDemoCaptionOverlay(step: step),
              if (showChrome.value)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: GestureDetector(
                        onTap: () {}, // absorb — don't toggle via parent
                        child: _DemoChrome(
                          caption: step.caption.replaceAll('\n', ' '),
                          progress: progress,
                          playing: playing.value,
                          finished: finished.value,
                          onClose: () => Navigator.of(context).maybePop(),
                          onPlayPause: () {
                            if (playing.value) {
                              pause();
                            } else {
                              startOrResume();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoChrome extends StatelessWidget {
  const _DemoChrome({
    required this.caption,
    required this.progress,
    required this.playing,
    required this.finished,
    required this.onClose,
    required this.onPlayPause,
  });

  final String caption;
  final double progress;
  final bool playing;
  final bool finished;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    finished
                        ? 'Done — tap to replay'
                        : playing
                        ? 'Playing — tap to pause'
                        : 'Tap play, then start screen recording',
                    style: AppTextStyles.caption().copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: AppTextStyles.label().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white12,
                color: const Color(0xFFFF3B5C),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onPlayPause,
              icon: Icon(
                finished
                    ? Icons.replay_rounded
                    : playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                finished
                    ? 'Replay'
                    : playing
                    ? 'Pause'
                    : 'Play demo',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B5C),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
