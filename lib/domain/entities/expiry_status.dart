/// Tiers per the product description §5.5 and §9. `critical` and `warning` are
/// separate because they render differently, but both answer to the list's
/// "Expiring soon" chip.
enum ExpiryStatus { ok, warning, critical, expired, none }

extension ExpiryStatusX on ExpiryStatus {
  bool get isExpiringSoon =>
      this == ExpiryStatus.warning || this == ExpiryStatus.critical;
}

const Duration criticalWindow = Duration(days: 7);
const Duration expiringSoonWindow = Duration(days: 30);

/// Day 0 counts as expired and both windows are inclusive of their last day, so
/// every comparison is `<=`. Dates are compared date-only: a lot does not change
/// status partway through the day it expires.
ExpiryStatus expiryStatusFor({
  required DateTime? nearestExpiry,
  required bool hasStock,
  required DateTime today,
}) {
  if (!hasStock) return ExpiryStatus.none;
  if (nearestExpiry == null) return ExpiryStatus.ok;

  final expiry = DateTime(nearestExpiry.year, nearestExpiry.month, nearestExpiry.day);
  final start = DateTime(today.year, today.month, today.day);

  if (!expiry.isAfter(start)) return ExpiryStatus.expired;

  final away = expiry.difference(start);
  if (away <= criticalWindow) return ExpiryStatus.critical;
  if (away <= expiringSoonWindow) return ExpiryStatus.warning;
  return ExpiryStatus.ok;
}
