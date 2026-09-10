import 'dart:convert';

/// Homeworks.attachmentPaths and Notes.imagePaths are stored as
/// JSON-encoded string lists in a single TEXT column (see
/// core/database/tables.dart) rather than a join table, since these are
/// small, order-preserving, always-loaded-with-the-parent lists. These
/// two helpers are the single place that encoding/decoding happens so
/// every feature reads/writes the column the same way.
List<String> decodeStringList(String raw) {
  if (raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
    return const [];
  } catch (_) {
    return const [];
  }
}

String encodeStringList(List<String> values) => jsonEncode(values);
