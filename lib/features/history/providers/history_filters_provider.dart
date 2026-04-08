import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_filters_provider.g.dart';

class HistoryFilters {
  const HistoryFilters({this.subjectSlug, this.mode});

  final String? subjectSlug;
  final String? mode;

  HistoryFilters copyWith({String? subjectSlug, String? mode, bool clearSubject = false, bool clearMode = false}) {
    return HistoryFilters(
      subjectSlug: clearSubject ? null : (subjectSlug ?? this.subjectSlug),
      mode: clearMode ? null : (mode ?? this.mode),
    );
  }
}

@Riverpod(keepAlive: true)
class HistoryFilterState extends _$HistoryFilterState {
  @override
  HistoryFilters build() => const HistoryFilters();

  void setAll() => state = const HistoryFilters();
  void setSubject(String? slug) => state = state.copyWith(subjectSlug: slug, clearSubject: slug == null);
  void setMode(String? mode) => state = state.copyWith(mode: mode, clearMode: mode == null);
}
