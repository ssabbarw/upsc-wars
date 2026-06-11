import 'dart:math';

/// Deterministic shuffle (seeded) for reproducible board layouts.
List<int> shuffleIndices(int length, int seed) {
  final order = List<int>.generate(length, (i) => i);
  final rng = Random(seed);
  for (var i = length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = order[i];
    order[i] = order[j];
    order[j] = tmp;
  }
  return order;
}
