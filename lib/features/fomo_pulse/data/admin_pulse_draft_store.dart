import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/fomo_pulse_models.dart';

/// Status of an admin-saved Pulse draft.
enum AdminPulseDraftStatus { draft, sentSelf, sentBroadcast }

/// A locally-saved Pulse draft created by an admin from a URL or harvest item.
/// Stored in shared_preferences so LLM generation is not repeated unnecessarily.
class AdminPulseDraft {
  const AdminPulseDraft({
    required this.id,
    required this.savedAt,
    required this.status,
    required this.draft,
  });

  /// Unique key: sha1-ish string derived from sourceUrl (or harvest id).
  final String id;
  final DateTime savedAt;
  final AdminPulseDraftStatus status;
  final FomoPulseDraft draft;

  /// Derive a stable id from a URL or harvest identifier.
  static String idFromUrl(String url) {
    var h = 0;
    for (final c in url.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  AdminPulseDraft copyWith({
    AdminPulseDraftStatus? status,
    FomoPulseDraft? draft,
  }) {
    return AdminPulseDraft(
      id: id,
      savedAt: savedAt,
      status: status ?? this.status,
      draft: draft ?? this.draft,
    );
  }

  Map<String, dynamic> toJson() {
    final q = draft.question;
    return {
      'id': id,
      'savedAt': savedAt.millisecondsSinceEpoch,
      'status': status.name,
      'draft': {
        'notificationTitle': draft.notificationTitle,
        'notificationBody': draft.notificationBody,
        'newsSummary': draft.newsSummary,
        'sourceUrl': draft.sourceUrl,
        'harvestDraftDate': draft.harvestDraftDate,
        'harvestDraftId': draft.harvestDraftId,
        'imageUrl': draft.imageUrl,
        'imageSource': draft.imageSource,
        'upscPoints': draft.upscPoints,
        'newsSummaryHi': draft.newsSummaryHi,
        'upscPointsHi': draft.upscPointsHi,
        'question': q.toServerMap(),
      },
    };
  }

  factory AdminPulseDraft.fromJson(Map<String, dynamic> json) {
    final d = json['draft'] as Map<String, dynamic>? ?? {};
    final status = AdminPulseDraftStatus.values.firstWhere(
      (e) => e.name == (json['status'] ?? 'draft'),
      orElse: () => AdminPulseDraftStatus.draft,
    );
    final points = d['upscPoints'];
    final pointsHi = d['upscPointsHi'];
    return AdminPulseDraft(
      id: json['id']?.toString() ?? '',
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['savedAt'] as num?)?.toInt() ?? 0,
      ),
      status: status,
      draft: FomoPulseDraft(
        notificationTitle: d['notificationTitle']?.toString() ?? '',
        notificationBody: d['notificationBody']?.toString() ?? '',
        newsSummary: d['newsSummary']?.toString() ?? '',
        sourceUrl: d['sourceUrl']?.toString() ?? '',
        harvestDraftDate: d['harvestDraftDate']?.toString(),
        harvestDraftId: d['harvestDraftId']?.toString(),
        imageUrl: d['imageUrl']?.toString() ?? '',
        imageSource: d['imageSource']?.toString() ?? '',
        upscPoints: points is List
            ? [for (final p in points) p.toString()]
            : const [],
        newsSummaryHi: d['newsSummaryHi']?.toString() ?? '',
        upscPointsHi: pointsHi is List
            ? [for (final p in pointsHi) p.toString()]
            : const [],
        question: FomoPulseQuestion.fromMap(
          d['question'] is Map
              ? Map<String, dynamic>.from(d['question'] as Map)
              : null,
        ),
      ),
    );
  }
}

/// Persists admin Pulse drafts in shared_preferences.
class AdminPulseDraftStore {
  static const _key = 'admin_pulse_drafts_v1';
  static const _maxDrafts = 30;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<AdminPulseDraft>> loadAll() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final drafts = <AdminPulseDraft>[];
      for (final item in decoded) {
        if (item is Map) {
          try {
            drafts
                .add(AdminPulseDraft.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
      drafts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return drafts;
    } catch (_) {
      return const [];
    }
  }

  /// Upsert a draft (insert or update by id), newest first.
  Future<void> save(AdminPulseDraft entry) async {
    final all = await loadAll();
    final next = [
      entry,
      ...all.where((d) => d.id != entry.id),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    final trimmed = next.take(_maxDrafts).toList();
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _key,
      jsonEncode([for (final d in trimmed) d.toJson()]),
    );
  }

  /// Update only the status of an existing draft.
  Future<void> updateStatus(String id, AdminPulseDraftStatus status) async {
    final all = await loadAll();
    final idx = all.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final updated = all[idx].copyWith(status: status);
    await save(updated);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    final next = all.where((d) => d.id != id).toList();
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _key,
      jsonEncode([for (final d in next) d.toJson()]),
    );
  }
}
