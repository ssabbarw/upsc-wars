import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full access today. A later Remote Config flag (`stats_paywall_enabled`)
/// plus a purchase entitlement can return [StatsAccess.preview].
enum StatsAccess { full, preview }

final statsAccessProvider = Provider<StatsAccess>((ref) => StatsAccess.full);
