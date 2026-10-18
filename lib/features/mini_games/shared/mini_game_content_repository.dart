import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mini_game_models.dart';

/// Abstract content source per game type. Swap asset JSON → Drift later
/// by providing a different implementation; controllers stay unchanged.
abstract class TimelineSorterRepository {
  Future<List<TimelineSorterSet>> loadSets();
}

abstract class OddOneOutRepository {
  Future<List<OddOneOutItem>> loadItems();
}

abstract class FactOrBluffRepository {
  Future<List<FactOrBluffItem>> loadItems();
}

abstract class ConnectTheDotsRepository {
  Future<List<ConnectTheDotsItem>> loadItems();
}

abstract class DuelRepository {
  Future<List<DuelQuestion>> loadQuestions();
}

class AssetTimelineSorterRepository implements TimelineSorterRepository {
  const AssetTimelineSorterRepository();

  @override
  Future<List<TimelineSorterSet>> loadSets() async {
    final raw = await rootBundle.loadString(
      'assets/mini_games/timeline_sorter.json',
    );
    final list = json.decode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(TimelineSorterSet.fromJson)
        .toList(growable: false);
  }
}

class AssetOddOneOutRepository implements OddOneOutRepository {
  const AssetOddOneOutRepository();

  @override
  Future<List<OddOneOutItem>> loadItems() async {
    final raw = await rootBundle.loadString(
      'assets/mini_games/odd_one_out.json',
    );
    final list = json.decode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(OddOneOutItem.fromJson)
        .toList(growable: false);
  }
}

class AssetFactOrBluffRepository implements FactOrBluffRepository {
  const AssetFactOrBluffRepository();

  @override
  Future<List<FactOrBluffItem>> loadItems() async {
    final raw = await rootBundle.loadString(
      'assets/mini_games/fact_or_bluff.json',
    );
    final list = json.decode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(FactOrBluffItem.fromJson)
        .toList(growable: false);
  }
}

class AssetConnectTheDotsRepository implements ConnectTheDotsRepository {
  const AssetConnectTheDotsRepository();

  @override
  Future<List<ConnectTheDotsItem>> loadItems() async {
    final raw = await rootBundle.loadString(
      'assets/mini_games/connect_the_dots.json',
    );
    final list = json.decode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(ConnectTheDotsItem.fromJson)
        .toList(growable: false);
  }
}

class AssetDuelRepository implements DuelRepository {
  const AssetDuelRepository();

  @override
  Future<List<DuelQuestion>> loadQuestions() async {
    final raw = await rootBundle.loadString('assets/mini_games/duel.json');
    final list = json.decode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(DuelQuestion.fromJson)
        .toList(growable: false);
  }
}

final timelineSorterRepositoryProvider = Provider<TimelineSorterRepository>(
  (ref) => const AssetTimelineSorterRepository(),
);

final oddOneOutRepositoryProvider = Provider<OddOneOutRepository>(
  (ref) => const AssetOddOneOutRepository(),
);

final factOrBluffRepositoryProvider = Provider<FactOrBluffRepository>(
  (ref) => const AssetFactOrBluffRepository(),
);

final connectTheDotsRepositoryProvider = Provider<ConnectTheDotsRepository>(
  (ref) => const AssetConnectTheDotsRepository(),
);

final duelRepositoryProvider = Provider<DuelRepository>(
  (ref) => const AssetDuelRepository(),
);
