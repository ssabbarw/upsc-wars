import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';

class OddOneOutState {
  const OddOneOutState({
    required this.items,
    required this.index,
    this.selectedIndex,
    this.revealed = false,
    this.error,
  });

  final List<OddOneOutItem> items;
  final int index;
  final int? selectedIndex;
  final bool revealed;
  final String? error;

  OddOneOutItem? get current =>
      items.isEmpty ? null : items[index % items.length];

  OddOneOutState copyWith({
    List<OddOneOutItem>? items,
    int? index,
    int? selectedIndex,
    bool clearSelected = false,
    bool? revealed,
    String? error,
  }) {
    return OddOneOutState(
      items: items ?? this.items,
      index: index ?? this.index,
      selectedIndex:
          clearSelected ? null : (selectedIndex ?? this.selectedIndex),
      revealed: revealed ?? this.revealed,
      error: error ?? this.error,
    );
  }
}

class OddOneOutController extends AsyncNotifier<OddOneOutState> {
  @override
  Future<OddOneOutState> build() async {
    final items = await ref.read(oddOneOutRepositoryProvider).loadItems();
    if (items.isEmpty) {
      return const OddOneOutState(
        items: [],
        index: 0,
        error: 'No odd-one-out items found.',
      );
    }
    return OddOneOutState(items: items, index: 0);
  }

  void select(int itemIndex) {
    final current = state.asData?.value;
    if (current == null || current.revealed || current.current == null) return;
    state = AsyncData(
      current.copyWith(selectedIndex: itemIndex, revealed: true),
    );
  }

  void next() {
    final current = state.asData?.value;
    if (current == null || current.items.isEmpty) return;
    final nextIndex = (current.index + 1) % current.items.length;
    state = AsyncData(
      current.copyWith(
        index: nextIndex,
        clearSelected: true,
        revealed: false,
      ),
    );
  }
}

final oddOneOutControllerProvider =
    AsyncNotifierProvider.autoDispose<OddOneOutController, OddOneOutState>(
  OddOneOutController.new,
);
