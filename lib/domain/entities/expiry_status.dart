enum ExpiryStatus { healthy, expiringSoon, expired, none }

const Duration expiringSoonWindow = Duration(days: 30);

/// Day 30 counts as expiring soon and day 0 counts as expired, so both
/// comparisons are inclusive. Dates are compared date-only, so a lot does not
/// change status partway through the day it expires.
ExpiryStatus expiryStatusFor({
  required DateTime? nearestExpiry,
  required bool hasStock,
  required DateTime today,
}) {
  if (!hasStock) return ExpiryStatus.none;
  if (nearestExpiry == null) return ExpiryStatus.healthy;

  final expiry = DateTime(nearestExpiry.year, nearestExpiry.month, nearestExpiry.day);
  final start = DateTime(today.year, today.month, today.day);

  if (!expiry.isAfter(start)) return ExpiryStatus.expired;
  return expiry.difference(start) <= expiringSoonWindow
      ? ExpiryStatus.expiringSoon
      : ExpiryStatus.healthy;
}
