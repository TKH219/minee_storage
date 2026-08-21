extension StringExt on String? {
  bool get isBlank => this == null || this!.trim().isEmpty;

  bool get isNotBlank => !isBlank;

  String get orEmpty => this ?? '';
}

extension NonNullStringExt on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String truncate(int max, {String ellipsis = '…'}) {
    if (length <= max) return this;
    return '${substring(0, max).trimRight()}$ellipsis';
  }
}

/// Normalises a user-typed shop link, or returns null when there is nothing
/// usable. A bare domain gains `https://`, since that is what people type.
String? normalisedUrlOrNull(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  // Uri.tryParse happily percent-encodes spaces into a "valid" host, so
  // anything with whitespace is rejected before it gets that chance.
  if (trimmed.contains(RegExp(r'\s'))) return null;

  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || !uri.isAbsolute || !uri.host.contains('.')) return null;
  return uri.toString();
}
