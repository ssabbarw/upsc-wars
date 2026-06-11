import 'memory_pair_models.dart';

String formatMemoryPairTime(int sec) {
  sec = sec < 0 ? 0 : sec;
  final m = sec ~/ 60;
  final s = sec % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

int starsForTime(int sec, int pairs) {
  if (pairs <= 0) return 1;
  final perPair = sec / pairs;
  if (perPair <= 5) return 5;
  if (perPair <= 7) return 4;
  if (perPair <= 9) return 3;
  if (perPair <= 12) return 2;
  return 1;
}

int starsForResult(MemoryPairGameResult result) =>
    starsFor(result.seconds, result.pairsCount, result.errors);

int starsFor(int sec, int pairs, int errors) {
  final base = starsForTime(sec, pairs);
  final step = (pairs / 3).round().clamp(2, pairs);
  final penalty = step > 0 ? errors ~/ step : 0;
  return (base - penalty).clamp(1, 5);
}

String starVerdict(int stars) => switch (stars) {
      5 => 'Razor sharp',
      4 => 'Strong recall',
      3 => 'Solid, can be faster',
      2 => 'Recall is slow',
      _ => 'Needs heavy revision',
    };
