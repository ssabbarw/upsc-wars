import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../auth/auth_session.dart';
import '../database/user_db.dart';
import 'session_backup_codec.dart';

/// Backs up the learner's bookmarks as **one document per account**
/// (`user_backups/{uid}/meta/bookmarks`).
///
/// Unlike test attempts, bookmarks are a small mutable set, so a single doc is
/// the cheapest layout: one write per change, one read on restore. Even a few
/// thousand bookmarks is ~100 KB, far under Firestore's 1 MiB limit.
///
/// Change detection is a content hash stored per uid in prefs, so:
///  * every mutation path (two repositories today) is covered by watching the
///    table once instead of hooking each call site;
///  * a failed upload simply leaves the hash stale and is retried;
///  * existing users' bookmarks are picked up with no separate backfill flag
///    (no stored hash yet = needs upload).
class BookmarkBackupService {
  BookmarkBackupService({
    required UserDatabase userDb,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = userDb,
       _firestoreOverride = firestore,
       _authOverride = auth;

  final UserDatabase _db;
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static const _uuid = Uuid();
  static const _commitTimeout = Duration(seconds: 25);

  /// Waits for a burst of bookmark taps to settle before writing.
  static const _debounce = Duration(seconds: 4);

  /// Mirrors the cap in `firestore.rules`.
  static const maxBookmarksPerDoc = 5000;

  static const docId = 'bookmarks';
  static const _kVersion = 'v';
  static const _kItems = 'items';
  static const _kUuid = 'u';
  static const _kCreatedMs = 'at';
  static const _kNote = 'n';
  static const _kCaDate = 'd';
  static const _kUpdatedAt = 'updatedAt';

  String? get _uid {
    final user = _auth.currentUser;
    return AuthSession.isAccountSignedIn(user) ? user!.uid : null;
  }

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection(SessionBackupFormat.collectionName)
      .doc(uid)
      .collection('meta')
      .doc(docId);

  static String _hashKey(String uid) => 'backup_bookmarks_hash_$uid';

  /// Stable fingerprint of the bookmark set (uuid, time, note).
  @visibleForTesting
  static String fingerprint(List<Bookmark> rows) {
    final parts = [
      for (final b in rows)
        '${b.questionUuid}|${b.createdAt.millisecondsSinceEpoch}|'
            '${b.userNote ?? ''}',
    ]..sort();
    // FNV-1a 64-bit-ish over the joined string; collisions only cost a
    // skipped upload until the next change.
    var h = 0xcbf29ce484222325;
    for (final unit in parts.join('\n').codeUnits) {
      h ^= unit;
      h = (h * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return '${parts.length}:${h.toRadixString(16)}';
  }

  // ---------------------------------------------------------------------------
  // Backup
  // ---------------------------------------------------------------------------

  /// Uploads the bookmark set if it differs from what was last uploaded for
  /// this account. Local-only (no Firestore) when nothing changed.
  Future<bool> syncIfChanged() async {
    try {
      final uid = _uid;
      if (uid == null) return false;
      final rows = await _db.bookmarksDao
          .getAllBookmarksOrderedByCreatedAtDesc();
      final prefs = await SharedPreferences.getInstance();
      final key = _hashKey(uid);
      final stored = prefs.getString(key);
      final hash = fingerprint(rows);
      if (stored == hash) return true;

      if (rows.isEmpty && stored == null) {
        // Never uploaded and nothing to upload: do not create an empty doc
        // that could mask a cloud backup the user has not restored yet.
        await prefs.setString(key, hash);
        return true;
      }
      if (rows.length > maxBookmarksPerDoc) return false;

      final questions = await _db.questionsDao.getByUuidsInOrder([
        for (final b in rows) b.questionUuid,
      ]);
      final caDates = {
        for (final q in questions)
          if (q.sourceDate != null && q.sourceDate!.isNotEmpty)
            q.uuid: q.sourceDate!,
      };

      await _docRef(uid)
          .set({
            _kVersion: 1,
            _kItems: [
              for (final b in rows)
                {
                  _kUuid: b.questionUuid,
                  _kCreatedMs: b.createdAt.millisecondsSinceEpoch,
                  if (b.userNote != null && b.userNote!.isNotEmpty)
                    _kNote: b.userNote,
                  if (caDates[b.questionUuid] != null)
                    _kCaDate: caDates[b.questionUuid],
                },
            ],
            _kUpdatedAt: FieldValue.serverTimestamp(),
          })
          .timeout(_commitTimeout);
      await prefs.setString(key, hash);
      return true;
    } on TimeoutException {
      return false; // offline: hash stays stale, retried on next change/scan
    } catch (e, st) {
      debugPrint('BookmarkBackupService.syncIfChanged: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  /// Watches the bookmarks table and uploads after changes settle. Covers every
  /// add/remove path. Call only **after** [restore] for this account, so a
  /// fresh install can never overwrite the cloud copy with a partial set.
  ///
  /// Returns a function that stops watching.
  void Function() startWatching() {
    Timer? timer;
    final sub = _db.select(_db.bookmarks).watch().listen((_) {
      timer?.cancel();
      timer = Timer(_debounce, () => unawaited(syncIfChanged()));
    });
    return () {
      timer?.cancel();
      unawaited(sub.cancel());
    };
  }

  // ---------------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------------

  /// Merges the cloud bookmark set into the local DB (never deletes). Newly
  /// restored bookmarks also get a revision-queue entry if absent, matching
  /// what bookmarking does live.
  ///
  /// Returns how many bookmarks were added. Throws on network/permission
  /// errors so the caller can offer a retry.
  Future<int> restore({
    Future<void> Function(String isoDate)? ensureCaDate,
  }) async {
    final uid = _uid;
    if (uid == null) return 0;
    final snap = await _docRef(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return 0;
    final raw = data[_kItems];
    if (raw is! List || raw.isEmpty) return 0;

    final items = <({String uuid, DateTime at, String? note, String? date})>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final uuid = e[_kUuid];
      final at = e[_kCreatedMs];
      if (uuid is! String || uuid.isEmpty || at is! num) continue;
      items.add((
        uuid: uuid,
        at: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
        note: e[_kNote] as String?,
        date: e[_kCaDate] as String?,
      ));
    }
    if (items.isEmpty) return 0;

    if (ensureCaDate != null) {
      final present = {
        for (final q in await _db.questionsDao.getByUuidsInOrder([
          for (final i in items) i.uuid,
        ]))
          q.uuid,
      };
      final dates = <String>{
        for (final i in items)
          if (i.date != null && !present.contains(i.uuid)) i.date!,
      }.toList()..sort();
      for (final d in dates) {
        try {
          await ensureCaDate(d);
        } catch (e) {
          debugPrint('BookmarkBackupService: CA $d not restored: $e');
        }
      }
    }

    var added = 0;
    for (final i in items) {
      if (await _db.bookmarksDao.isQuestionBookmarked(i.uuid)) continue;
      await _db.bookmarksDao.insertBookmark(
        BookmarksCompanion.insert(
          id: _uuid.v4(),
          questionUuid: i.uuid,
          createdAt: i.at,
          userNote: Value(i.note),
        ),
      );
      added++;
      if (await _db.revisionQueueDao.getRevisionQueueItemByQuestionUuid(
            i.uuid,
          ) ==
          null) {
        await _db.revisionQueueDao.add(
          id: _uuid.v4(),
          questionUuid: i.uuid,
          dateAddedToQueue: i.at,
        );
      }
    }
    return added;
  }
}
