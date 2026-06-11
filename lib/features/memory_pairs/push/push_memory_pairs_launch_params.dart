import 'package:firebase_messaging/firebase_messaging.dart';

import '../data/memory_pair_sets_data.dart';
import 'push_memory_pairs_fcm.dart';

/// Launch inputs for push / deep link / debug UI → welcome screen.
class PushMemoryPairsLaunchParams {
  const PushMemoryPairsLaunchParams({
    required this.setId,
    this.title,
    this.body,
  });

  final String setId;
  final String? title;
  final String? body;

  bool get isValid {
    final id = setId.trim();
    if (id.isEmpty) return false;
    return memoryPairSetById(id)?.hasPlayablePairs ?? false;
  }

  String? get validationError {
    final id = setId.trim();
    if (id.isEmpty) return 'Missing set id.';
    final set = memoryPairSetById(id);
    if (set == null) return 'Unknown set: $id';
    if (!set.hasPlayablePairs) return 'Set has no playable pairs.';
    return null;
  }

  Map<String, String> toQueryParameters() => {
        'set': setId.trim(),
        if (title != null && title!.trim().isNotEmpty) 'title': title!.trim(),
        if (body != null && body!.trim().isNotEmpty) 'body': body!.trim(),
      };

  String get welcomeLocation {
    final uri = Uri(
      path: '/memory-pairs/welcome',
      queryParameters: toQueryParameters(),
    );
    return uri.toString();
  }

  String get autoplayGameLocation {
    final uri = Uri(
      path: '/memory-pairs',
      queryParameters: {
        'set': setId.trim(),
        'autoplay': '1',
      },
    );
    return uri.toString();
  }

  static PushMemoryPairsLaunchParams fromQuery(Map<String, String> q) {
    final id = q['set'] ?? q['id'] ?? q['set_id'] ?? '';
    return PushMemoryPairsLaunchParams(
      setId: id.trim(),
      title: q['title'] ?? q['heading'],
      body: q['body'],
    );
  }

  static PushMemoryPairsLaunchParams fromRemoteMessage(RemoteMessage message) {
    return PushMemoryPairsLaunchParams(
      setId: PushMemoryPairsFcm.setIdFromData(message.data) ?? '',
      title: PushMemoryPairsFcm.titleFromMessage(message),
      body: PushMemoryPairsFcm.bodyFromMessage(message),
    );
  }
}
