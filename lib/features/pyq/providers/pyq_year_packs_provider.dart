import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/pyq_constants.dart';
import '../../../core/providers/user_database_provider.dart';

class PyqYearPacksData {
  const PyqYearPacksData({
    required this.year,
    required this.subject,
    required this.packUuids,
    required this.packCompleted,
  });

  final String year;
  final String subject;
  final List<List<String>> packUuids;
  final List<bool> packCompleted;
}

final pyqYearPacksDataProvider = FutureProvider.autoDispose
    .family<PyqYearPacksData, String>((ref, year) async {
      final subject = PyqConstants.subjectSlugForYear(year);
      final db = ref.watch(userDatabaseProvider);
      final questions = await db.questionsDao.getBySubjectPaperOrder(subject);
      if (questions.isEmpty) {
        return PyqYearPacksData(
          year: year,
          subject: subject,
          packUuids: const [],
          packCompleted: const [],
        );
      }
      final perPack = PyqConstants.questionsPerPack;
      final packs = <List<String>>[];
      for (var i = 0; i < questions.length; i += perPack) {
        final end = i + perPack > questions.length
            ? questions.length
            : i + perPack;
        packs.add(questions.sublist(i, end).map((q) => q.uuid).toList());
      }
      final done = <bool>[];
      for (var j = 0; j < packs.length; j++) {
        done.add(
          await db.sessionsDao.hasCompletedPyqPack(
            subject: subject,
            packIndex: j,
          ),
        );
      }
      return PyqYearPacksData(
        year: year,
        subject: subject,
        packUuids: packs,
        packCompleted: done,
      );
    });
