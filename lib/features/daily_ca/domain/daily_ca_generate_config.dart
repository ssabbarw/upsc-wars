/// When the Cloud Function should generate tonight's English drafts (IST).
class DailyCaGenerateConfig {
  const DailyCaGenerateConfig({
    required this.hourIst,
    required this.minuteIst,
  });

  static const defaultHourIst = 20;
  static const defaultMinuteIst = 0;

  final int hourIst;
  final int minuteIst;

  factory DailyCaGenerateConfig.fromMap(Map<String, dynamic>? data) {
    final hour = _clamp(
      _asInt(data?['generate_hour_ist'], defaultHourIst),
      0,
      23,
    );
    final minute = _clamp(
      _asInt(data?['generate_minute_ist'], defaultMinuteIst),
      0,
      59,
    );
    return DailyCaGenerateConfig(hourIst: hour, minuteIst: minute);
  }

  Map<String, int> toMap() => {
    'generate_hour_ist': hourIst,
    'generate_minute_ist': minuteIst,
  };

  String get labelIst {
    final h = hourIst % 12 == 0 ? 12 : hourIst % 12;
    final ampm = hourIst >= 12 ? 'PM' : 'AM';
    final m = minuteIst.toString().padLeft(2, '0');
    return '$h:$m $ampm IST';
  }

  DailyCaGenerateConfig copyWith({int? hourIst, int? minuteIst}) {
    return DailyCaGenerateConfig(
      hourIst: hourIst ?? this.hourIst,
      minuteIst: minuteIst ?? this.minuteIst,
    );
  }
}

int _asInt(Object? raw, int fallback) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
  return fallback;
}

int _clamp(int v, int min, int max) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}
