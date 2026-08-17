import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/daily_ca_admin_cloud_service.dart';
import '../data/daily_ca_firestore.dart';
import '../domain/daily_ca_draft.dart';

final dailyCaAdminCloudServiceProvider = Provider<DailyCaAdminCloudService>(
  (ref) => DailyCaAdminCloudService(),
);

final dailyCaDraftProvider = FutureProvider.autoDispose
    .family<DailyCaDraft?, String>((ref, isoDate) async {
      final snap = await DailyCaFirestore.draftDoc(isoDate).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return DailyCaDraft.fromDoc(isoDate, data);
    });
