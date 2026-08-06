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
