import 'dart:convert';

/// Kinds of tests inside a series (mirrors the generator / Cloud Function).
abstract final class SeriesTestKind {
  static const staticTest = 'static';
  static const pyqMix = 'pyq_mix';
  static const currentAffairs = 'ca';
  static const fullLength = 'flt';
}

/// Bucket ids used by static tests (mirrors `tools/test_series/generate_series.py`).
abstract final class SeriesBuckets {
  static const polity = 'polity';
  static const economy = 'economy';
  static const environment = 'environment';
  static const geography = 'geography';
  static const modernHistory = 'modern_history';
  static const historyCulture = 'history_culture';

  /// Whole-syllabus tests. Not a subject: it is not in [staticOrder].
  static const fullSyllabus = 'full_syllabus';

  /// Display order of the static subject buckets.
  static const staticOrder = [
    polity,
    economy,
    environment,
    geography,
    modernHistory,
    historyCulture,
  ];

  static const _en = {
    polity: 'Polity',
    economy: 'Economy',
    environment: 'Environment',
    geography: 'Geography',
    modernHistory: 'Modern History',
    historyCulture: 'Ancient, Medieval & Art and Culture',
    fullSyllabus: 'Full Syllabus',
  };

  static const _hi = {
    polity: 'राजव्यवस्था',
    economy: 'अर्थव्यवस्था',
    environment: 'पर्यावरण',
    geography: 'भूगोल',
    modernHistory: 'आधुनिक इतिहास',
    historyCulture: 'प्राचीन, मध्यकालीन इतिहास और कला-संस्कृति',
    fullSyllabus: 'पूर्ण पाठ्यक्रम',
  };

  static String label(String bucket, {bool hindi = false}) =>
      (hindi ? _hi[bucket] : _en[bucket]) ?? _en[bucket] ?? bucket;
}

/// One question slot of a series test.
class SeriesQuestionRef {
  const SeriesQuestionRef({
    required this.uuid,
    required this.kind,
    this.pyqYear,
    this.date,
    this.sourceMonth,
  });

  final String uuid;

  /// `static` | `pyq` | `ca`.
  final String kind;
  final int? pyqYear;

  /// `YYYY-MM-DD` of the daily CA day (only for `ca`). Used to fetch the
  /// question; never shown to users.
  final String? date;

  /// `YYYY-MM` of the CA question (only for `ca`). Never shown to users.
  final String? sourceMonth;

  bool get isCa => kind == 'ca';

  factory SeriesQuestionRef.fromMap(Map<String, dynamic> m) {
    return SeriesQuestionRef(
      uuid: m['uuid'] as String,
      kind: (m['kind'] as String?) ?? 'static',
      pyqYear: (m['pyqYear'] as num?)?.toInt(),
      date: m['date'] as String?,
      sourceMonth: m['sourceMonth'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'uuid': uuid,
    'kind': kind,
    if (pyqYear != null) 'pyqYear': pyqYear,
    if (date != null) 'date': date,
    if (sourceMonth != null) 'sourceMonth': sourceMonth,
  };
}

/// Series metadata (`test_series/{seriesId}`).
class TestSeriesInfo {
  const TestSeriesInfo({
    required this.id,
    required this.title,
    required this.titleHi,
    required this.year,
    required this.productId,
    required this.entitlementId,
    this.prelimsDate,
    this.testCount = 0,
  });

  final String id;
  final String title;
  final String titleHi;
  final int year;
  final String productId;
  final String entitlementId;
  final DateTime? prelimsDate;
  final int testCount;

  String displayTitle({bool hindi = false}) =>
      hindi && titleHi.isNotEmpty ? titleHi : title;

  factory TestSeriesInfo.fromMap(String id, Map<String, dynamic> m) {
    return TestSeriesInfo(
      id: id,
      title: (m['title'] as String?) ?? 'Test Series',
      titleHi: (m['titleHi'] as String?) ?? '',
      year: (m['year'] as num?)?.toInt() ?? 0,
      productId: (m['productId'] as String?) ?? '${id}_pass',
      entitlementId: (m['entitlementId'] as String?) ?? id,
      prelimsDate: DateTime.tryParse((m['prelimsDate'] as String?) ?? ''),
      testCount: (m['testCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'titleHi': titleHi,
    'year': year,
    'productId': productId,
    'entitlementId': entitlementId,
    if (prelimsDate != null) 'prelimsDate': prelimsDate!.toIso8601String(),
    'testCount': testCount,
  };
}

/// One test of a series (`test_series/{seriesId}/tests/{testId}`).
class SeriesTest {
  const SeriesTest({
    required this.id,
    required this.seriesId,
    required this.kind,
    required this.bucket,
    required this.title,
    required this.index,
    required this.isFree,
    required this.unlockAt,
    required this.durationMins,
    required this.questionCount,
    required this.status,
    required this.questions,
    this.theme,
    this.themeTopics = const [],
  });

  final String id;
  final String seriesId;
  final String kind;
  final String bucket;
  final String title;
  final String? theme;
  final List<String> themeTopics;

  /// 1-based position within its kind/bucket.
  final int index;
  final bool isFree;
  final DateTime unlockAt;
  final int durationMins;
  final int questionCount;

  /// `ready` or `pending_ca` (current-affairs part not published yet).
  final String status;
  final List<SeriesQuestionRef> questions;

  bool get isReady => status == 'ready' && questions.isNotEmpty;
  bool get isCurrentAffairs => kind == SeriesTestKind.currentAffairs;
  bool get isFullLength => kind == SeriesTestKind.fullLength;

  /// True once the unlock date has passed and the paper is fully published.
  bool isAvailableAt(DateTime now) => isReady && !unlockAt.isAfter(now);

  /// True when the unlock date is in the future, or the paper is still
  /// waiting for its current-affairs questions.
  bool isUpcomingAt(DateTime now) => !isAvailableAt(now);

  factory SeriesTest.fromMap(String id, Map<String, dynamic> m) {
    final rawQuestions = (m['questions'] as List?) ?? const [];
    final kind = (m['kind'] as String?) ?? SeriesTestKind.staticTest;
    return SeriesTest(
      id: id,
      seriesId: (m['seriesId'] as String?) ?? '',
      kind: kind,
      bucket: (m['bucket'] as String?) ?? '',
      title: (m['title'] as String?) ?? id,
      theme: m['theme'] as String?,
      themeTopics: ((m['themeTopics'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      index: (m['index'] as num?)?.toInt() ?? 0,
      // PYQ-mix tests are always free, whatever the stored flag says.
      isFree: m['isFree'] == true || kind == SeriesTestKind.pyqMix,
      unlockAt: DateTime.fromMillisecondsSinceEpoch(
        (m['unlockAtMs'] as num?)?.toInt() ?? 0,
      ),
      durationMins: (m['durationMins'] as num?)?.toInt() ?? 60,
      questionCount: (m['questionCount'] as num?)?.toInt() ?? 0,
      status: (m['status'] as String?) ?? 'pending_ca',
      questions: rawQuestions
          .whereType<Map>()
          .map((e) => SeriesQuestionRef.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Plain-JSON map (used for the offline cache). `unlockAt` is stored as ms.
  Map<String, dynamic> toMap() => {
    'seriesId': seriesId,
    'kind': kind,
    'bucket': bucket,
    'title': title,
    'theme': theme,
    'themeTopics': themeTopics,
    'index': index,
    'isFree': isFree,
    'unlockAtMs': unlockAt.millisecondsSinceEpoch,
    'durationMins': durationMins,
    'questionCount': questionCount,
    'status': status,
    'questions': questions.map((q) => q.toMap()).toList(),
  };
}

/// A series plus all of its tests, sorted for display.
class SeriesBundle {
  const SeriesBundle({required this.info, required this.tests});

  final TestSeriesInfo info;
  final List<SeriesTest> tests;

  List<SeriesTest> ofKind(String kind) =>
      tests.where((t) => t.kind == kind).toList();

  List<SeriesTest> forBucket(String bucket) =>
      tests.where((t) => t.kind == SeriesTestKind.staticTest && t.bucket == bucket).toList();

  SeriesTest? byId(String id) {
    for (final t in tests) {
      if (t.id == id) return t;
    }
    return null;
  }

  String toJsonString() => jsonEncode({
    'info': {'id': info.id, ...info.toMap()},
    'tests': {for (final t in tests) t.id: t.toMap()},
  });

  static SeriesBundle? fromJsonString(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final infoMap = Map<String, dynamic>.from(m['info'] as Map);
      final info = TestSeriesInfo.fromMap(infoMap['id'] as String, infoMap);
      final tests = <SeriesTest>[];
      (m['tests'] as Map).forEach((k, v) {
        tests.add(SeriesTest.fromMap(k as String, Map<String, dynamic>.from(v as Map)));
      });
      return SeriesBundle(info: info, tests: sortSeriesTests(tests));
    } on Object {
      return null;
    }
  }
}

const _kindOrder = {
  SeriesTestKind.staticTest: 0,
  SeriesTestKind.pyqMix: 1,
  SeriesTestKind.currentAffairs: 2,
  SeriesTestKind.fullLength: 3,
};

/// Stable display order: kind, then bucket order, then test index.
List<SeriesTest> sortSeriesTests(List<SeriesTest> tests) {
  int bucketRank(SeriesTest t) {
    final i = SeriesBuckets.staticOrder.indexOf(t.bucket);
    return i < 0 ? 99 : i;
  }

  final out = [...tests];
  out.sort((a, b) {
    final k = (_kindOrder[a.kind] ?? 9).compareTo(_kindOrder[b.kind] ?? 9);
    if (k != 0) return k;
    final bk = bucketRank(a).compareTo(bucketRank(b));
    if (bk != 0) return bk;
    return a.index.compareTo(b.index);
  });
  return out;
}
