import 'package:uuid/uuid.dart';

/// Central ID generator so every feature creates IDs the same way,
/// without each screen importing `uuid` directly.
class IdGenerator {
  IdGenerator._();

  static const _uuid = Uuid();

  static String next() => _uuid.v4();
}
