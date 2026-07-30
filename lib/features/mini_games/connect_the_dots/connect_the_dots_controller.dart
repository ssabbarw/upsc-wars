import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';

class ConnectTheDotsState {
  const ConnectTheDotsState({
    required this.items,
    required this.index,
    this.selectedIndex,
    this.revealed = false,
    this.error,
  });

  final List<ConnectTheDotsItem> items;
  final int index;
  final int? selectedIndex;
  final bool revealed;
  final String? error;

  ConnectTheDotsItem? get current =>
      items.isEmpty ? null : items[index % items.length];

  ConnectTheDotsState copyWith({
    List<ConnectTheDotsItem>? items,
    int? index,
    int? selectedIndex,
    bool clearSelected = false,
    bool? revealed,
    String? error,
  }) {
    return ConnectTheDotsState(
      items: items ?? this.items,
      index: index ?? this.index,
      selectedIndex:
          clearSelected ? null : (selectedIndex ?? this.selectedIndex),
      revealed: revealed ?? this.revealed,
      error: error ?? this.error,
    );
  }
}

class ConnectTheDotsController extends AsyncNotifier<ConnectTheDotsState> {
  @override
  Future<ConnectTheDotsState> build() async {
    final items = await ref.read(connectTheDotsRepositoryProvider).loadItems();
    if (items.isEmpty) {
      return const ConnectTheDotsState(
        items: [],
        index: 0,
        error: 'No connect-the-dots items found.',
      );
    }
    return ConnectTheDotsState(items: items, index: 0);
  }

  void select(int optionIndex) {
    final current = state.asData?.value;
    if (current == null || current.revealed || current.current == null) return;
    state = AsyncData(
      current.copyWith(selectedIndex: optionIndex, revealed: true),
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

final connectTheDotsControllerProvider = AsyncNotifierProvider.autoDispose<
    ConnectTheDotsController, ConnectTheDotsState>(
  ConnectTheDotsController.new,
);
