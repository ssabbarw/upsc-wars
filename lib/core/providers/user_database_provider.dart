import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/user_db.dart';

part 'user_database_provider.g.dart';

@Riverpod(keepAlive: true)
UserDatabase userDatabase(Ref ref) => UserDatabase();
