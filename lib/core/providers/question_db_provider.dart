import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/question_db.dart';
import 'app_bootstrap.dart';

part 'question_db_provider.g.dart';

@Riverpod(keepAlive: true)
Future<QuestionDb> questionDb(Ref ref) async {
  await ref.watch(appBootstrapProvider.future);
  final dir = await getApplicationDocumentsDirectory();
  return QuestionDb(p.join(dir.path, 'upsc_wars_questions.db'));
}
