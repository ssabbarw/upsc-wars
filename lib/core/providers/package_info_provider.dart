import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_constants.dart';

/// Pubspec `version:` (name before `+build`), injected by Flutter at build time.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// In-app label from pubspec `version`, e.g. `2038.0.1` → `v2038.0.1`.
String appVersionLabel(PackageInfo info) {
  final v = info.version.trim();
  if (v.isEmpty) return '';
  return (v.startsWith('v') || v.startsWith('V')) ? v : 'v$v';
}

ReleaseVersion? releaseVersionFromPackageInfo(PackageInfo info) =>
    ReleaseVersion.parse(info.version);
