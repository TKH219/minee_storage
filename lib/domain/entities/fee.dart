import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Who ends up with the money, per §5.3. The four directions are what separate
/// what the buyer hands over from what the store actually keeps.
enum FeeDirection { discount, passThrough, buyerCharge, sellerCost }

extension FeeDirectionX on FeeDirection {
  bool get raisesBuyerTotal =>
      this == FeeDirection.passThrough || this == FeeDirection.buyerCharge;

  bool get isPassThrough => this == FeeDirection.passThrough;

  bool get isDiscount => this == FeeDirection.discount;
}

enum FeeKind { fixed, percent }

class Fee extends Equatable {
  const Fee({
    required this.id,
    required this.name,
    required this.kind,
    required this.value,
    required this.direction,
  });

  final String id;
  final String name;
  final FeeKind kind;
  final Decimal value;
  final FeeDirection direction;

  Fee copyWith({String? name, FeeKind? kind, Decimal? value, FeeDirection? direction}) {
    return Fee(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      direction: direction ?? this.direction,
    );
  }

  @override
  List<Object?> get props => [id, name, kind, value, direction];
}

/// A [Fee] resolved against a concrete basket: the amount it moved, and the
/// figure that amount was taken from when the fee is a percentage.
class ComputedFee extends Equatable {
  const ComputedFee({required this.fee, required this.amount, this.base});

  final Fee fee;
  final Decimal amount;

  /// Null for a fixed fee — there is no base to name.
  final Decimal? base;

  @override
  List<Object?> get props => [fee, amount, base];
}
