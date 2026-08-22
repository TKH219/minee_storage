/// The audit stamps every persisted row carries.
///
/// Null on an entity that has never been through the database — a default
/// constant, or a row built in a test.
mixin AuditTimes {
  DateTime? get createdTime;
  DateTime? get updatedTime;
  DateTime? get deletedTime;

  /// Soft delete. Rows with a deletion stamp are filtered out of every read.
  bool get isDeleted => deletedTime != null;
}

DateTime? parseTime(Map<String, dynamic> row, String key) {
  final raw = row[key] as String?;
  return raw == null ? null : DateTime.parse(raw);
}
