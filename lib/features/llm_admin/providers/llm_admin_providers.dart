import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/llm_admin_cloud_service.dart';

final llmAdminCloudServiceProvider = Provider<LlmAdminCloudService>(
  (ref) => LlmAdminCloudService(),
);
