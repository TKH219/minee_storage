/// Why stock left without being sold. Required on a write-off, absent elsewhere.
enum WriteOffReason { expired, damaged, lost, internalUse, other }

extension WriteOffReasonX on WriteOffReason {
  String get wireValue => switch (this) {
    WriteOffReason.expired => 'expired',
    WriteOffReason.damaged => 'damaged',
    WriteOffReason.lost => 'lost',
    WriteOffReason.internalUse => 'internal_use',
    WriteOffReason.other => 'other',
  };

  static WriteOffReason fromWire(String value) => switch (value) {
    'expired' => WriteOffReason.expired,
    'damaged' => WriteOffReason.damaged,
    'lost' => WriteOffReason.lost,
    'internal_use' => WriteOffReason.internalUse,
    'other' => WriteOffReason.other,
    _ => throw ArgumentError.value(value, 'reason', 'not a write-off reason'),
  };
}
