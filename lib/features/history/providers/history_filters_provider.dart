import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_filters_provider.g.dart';

class HistoryFilters {
  const HistoryFilters({this.subject, this.mode});

  final String? subject;
  final String? mode;

  HistoryFilters copyWith({
    String? subject,
    String? mode,
    bool clearSubject = false,
    bool clearMode = false,
  }) {
    return HistoryFilters(
      subject: clearSubject ? null : (subject ?? this.subject),
      mode: clearMode ? null : (mode ?? this.mode),
    );
  }
}

@Riverpod(keepAlive: true)
class HistoryFilterState extends _$HistoryFilterState {
  @override
  HistoryFilters build() => const HistoryFilters();

  void setAll() => state = const HistoryFilters();
  void setSubject(String? subject) =>
      state = state.copyWith(subject: subject, clearSubject: subject == null);
  void setMode(String? mode) =>
      state = state.copyWith(mode: mode, clearMode: mode == null);
}
