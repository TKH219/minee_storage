import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

enum AttentionAlertKind { expired, expiringSoon, outOfStock }

/// One row of the dashboard's Needs-attention block.
///
/// Every alert is a link into the screen that fixes it, so it names the
/// products behind it rather than only counting them.
class AttentionAlert extends Equatable {
  const AttentionAlert({
    required this.kind,
    required this.productNames,
    required this.count,
    this.valueAtCost,
  });

  final AttentionAlertKind kind;
  final List<String> productNames;
  final int count;

  /// What the affected stock cost to buy. Only [AttentionAlertKind.expiringSoon]
  /// carries one — it is the figure that turns a date into a decision.
  final Decimal? valueAtCost;

  @override
  List<Object?> get props => [kind, productNames, count, valueAtCost];
}
