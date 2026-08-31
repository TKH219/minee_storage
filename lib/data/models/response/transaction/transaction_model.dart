import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'transaction_model.g.dart';

/// Every money and quantity field is a [String] on the wire so a NUMERIC column
/// round-trips exactly. Parsing one into a double, at any point, is the drift
/// `numeric(18,2)` exists to prevent.
@JsonSerializable(createToJson: false)
class TransactionLineModel {
  const TransactionLineModel({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.batchId,
    required this.batchCode,
    required this.productName,
    required this.unit,
    required this.quantityDelta,
    required this.unitPrice,
    required this.unitCostSnapshot,
    this.quantityBefore,
    required this.lineGross,
    required this.lineCost,
    this.batchUnitCost,
    this.expiryDate,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory TransactionLineModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionLineModelFromJson(json);

  final String id;
  final String transactionId;
  final String productId;
  final String batchId;
  final String batchCode;
  final String productName;
  final String unit;
  final String quantityDelta;
  final String? quantityBefore;
  final String unitPrice;
  final String unitCostSnapshot;
  final String? batchUnitCost;
  final String lineGross;
  final String lineCost;
  final String? expiryDate;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  TransactionLine toEntity() => TransactionLine(
    id: id,
    transactionId: transactionId,
    productId: productId,
    batchId: batchId,
    batchCode: batchCode,
    productName: productName,
    unit: ProductUnit.fromCode(unit),
    quantityDelta: Decimal.parse(quantityDelta),
    quantityBefore: quantityBefore == null ? null : Decimal.parse(quantityBefore!),
    unitPrice: Decimal.parse(unitPrice),
    unitCostSnapshot: Decimal.parse(unitCostSnapshot),
    batchUnitCost: batchUnitCost == null ? null : Decimal.parse(batchUnitCost!),
    lineGross: Decimal.parse(lineGross),
    lineCost: Decimal.parse(lineCost),
    expiryDate: expiryDate == null ? null : DateTime.parse(expiryDate!),
    sortOrder: sortOrder,
    createdTime: createdAt == null ? null : DateTime.parse(createdAt!),
    updatedTime: updatedAt == null ? null : DateTime.parse(updatedAt!),
    deletedTime: deletedAt == null ? null : DateTime.parse(deletedAt!),
  );
}

@JsonSerializable(createToJson: false)
class TransactionFeeModel {
  const TransactionFeeModel({
    required this.id,
    required this.transactionId,
    required this.name,
    required this.direction,
    required this.kind,
    required this.value,
    required this.computedAmount,
    this.isPassThrough = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory TransactionFeeModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionFeeModelFromJson(json);

  final String id;
  final String transactionId;
  final String name;
  final String direction;
  final String kind;
  final String value;
  final bool isPassThrough;
  final String computedAmount;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  TransactionFee toEntity() => TransactionFee(
    id: id,
    transactionId: transactionId,
    name: name,
    direction: feeDirectionFromWire(direction, isPassThrough: isPassThrough),
    kind: feeKindFromWire(kind),
    value: Decimal.parse(value),
    computedAmount: Decimal.parse(computedAmount),
    sortOrder: sortOrder,
    createdTime: createdAt == null ? null : DateTime.parse(createdAt!),
    updatedTime: updatedAt == null ? null : DateTime.parse(updatedAt!),
    deletedTime: deletedAt == null ? null : DateTime.parse(deletedAt!),
  );
}

/// The wire carries a pass-through fee as `buyer_charge` plus a flag, because
/// that is what the money math keys on. The domain keeps it as its own
/// direction, so a screen can label it without consulting two fields.
FeeDirection feeDirectionFromWire(String direction, {required bool isPassThrough}) =>
    switch (direction) {
      'discount' => FeeDirection.discount,
      'seller_cost' => FeeDirection.sellerCost,
      'buyer_charge' =>
        isPassThrough ? FeeDirection.passThrough : FeeDirection.buyerCharge,
      _ => throw ArgumentError.value(direction, 'direction', 'not a fee direction'),
    };

String feeDirectionToWire(FeeDirection direction) => switch (direction) {
  FeeDirection.discount => 'discount',
  FeeDirection.sellerCost => 'seller_cost',
  FeeDirection.buyerCharge || FeeDirection.passThrough => 'buyer_charge',
};

FeeKind feeKindFromWire(String kind) => switch (kind) {
  'fixed' => FeeKind.fixed,
  'percent' => FeeKind.percent,
  _ => throw ArgumentError.value(kind, 'kind', 'not a fee kind'),
};

String feeKindToWire(FeeKind kind) =>
    kind == FeeKind.fixed ? 'fixed' : 'percent';

@JsonSerializable(createToJson: false)
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.storeId,
    required this.type,
    required this.code,
    required this.occurredAt,
    required this.itemsSubtotal,
    required this.discountTotal,
    required this.buyerChargeTotal,
    required this.sellerCostTotal,
    required this.passThroughTotal,
    required this.buyerTotal,
    required this.netRevenue,
    required this.cogs,
    required this.grossProfit,
    required this.netProfit,
    required this.netMargin,
    this.lines = const [],
    this.fees = const [],
    this.counterparty,
    this.counterpartyPhone,
    this.note,
    this.paymentMethod,
    this.reason,
    this.reasonNote,
    this.amendedAt,
    this.revision = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  final String id;
  final String storeId;
  final String type;
  final String code;
  final String occurredAt;
  final String itemsSubtotal;
  final String discountTotal;
  final String buyerChargeTotal;
  final String sellerCostTotal;
  final String passThroughTotal;
  final String buyerTotal;
  final String netRevenue;
  final String cogs;
  final String grossProfit;
  final String netProfit;
  final String netMargin;
  final List<TransactionLineModel> lines;
  final List<TransactionFeeModel> fees;
  final String? counterparty;
  final String? counterpartyPhone;
  final String? note;
  final String? paymentMethod;
  final String? reason;
  final String? reasonNote;
  final String? amendedAt;
  final int revision;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  Transaction toEntity() {
    final resolvedFees = fees.map((fee) => fee.toEntity()).toList();
    return Transaction(
      id: id,
      storeId: storeId,
      type: TransactionTypeX.fromWire(type),
      code: code,
      occurredAt: DateTime.parse(occurredAt),
      money: TransactionMoney(
        itemsSubtotal: Decimal.parse(itemsSubtotal),
        discountTotal: Decimal.parse(discountTotal),
        buyerChargeTotal: Decimal.parse(buyerChargeTotal),
        sellerCostTotal: Decimal.parse(sellerCostTotal),
        passThroughTotal: Decimal.parse(passThroughTotal),
        buyerTotal: Decimal.parse(buyerTotal),
        netRevenue: Decimal.parse(netRevenue),
        cogs: Decimal.parse(cogs),
        grossProfit: Decimal.parse(grossProfit),
        netProfit: Decimal.parse(netProfit),
        netMargin: Decimal.parse(netMargin),
        fees: [
          for (final fee in resolvedFees)
            ComputedFee(fee: fee.asFee, amount: fee.computedAmount),
        ],
      ),
      lines: lines.map((line) => line.toEntity()).toList(),
      fees: resolvedFees,
      counterparty: counterparty,
      counterpartyPhone: counterpartyPhone,
      note: note,
      paymentMethod:
          paymentMethod == null ? null : PaymentMethodX.fromWire(paymentMethod!),
      reason: reason == null ? null : WriteOffReasonX.fromWire(reason!),
      reasonNote: reasonNote,
      amendedAt: amendedAt == null ? null : DateTime.parse(amendedAt!),
      revision: revision,
      createdTime: createdAt == null ? null : DateTime.parse(createdAt!),
      updatedTime: updatedAt == null ? null : DateTime.parse(updatedAt!),
      deletedTime: deletedAt == null ? null : DateTime.parse(deletedAt!),
    );
  }
}

@JsonSerializable(createToJson: false)
class TransactionDayModel {
  const TransactionDayModel({
    required this.date,
    required this.subtotal,
    required this.transactionCount,
    this.transactions = const [],
  });

  factory TransactionDayModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionDayModelFromJson(json);

  final String date;

  /// The whole day's total, computed server-side. Never summed from
  /// [transactions] — a page may carry only part of a busy day.
  final String subtotal;
  final int transactionCount;
  final List<TransactionModel> transactions;

  TransactionDay toEntity() => TransactionDay(
    date: DateTime.parse(date),
    subtotal: Decimal.parse(subtotal),
    transactionCount: transactionCount,
    transactions: transactions.map((row) => row.toEntity()).toList(),
  );
}

@JsonSerializable(createToJson: false)
class TransactionPageModel {
  const TransactionPageModel({
    required this.page,
    required this.limit,
    required this.total,
    this.days = const [],
  });

  factory TransactionPageModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionPageModelFromJson(json);

  final List<TransactionDayModel> days;
  final int page;
  final int limit;
  final int total;

  TransactionPage toEntity() => TransactionPage(
    days: days.map((day) => day.toEntity()).toList(),
    page: page,
    limit: limit,
    total: total,
  );
}

@JsonSerializable(createToJson: false)
class ResolvedLineModel {
  const ResolvedLineModel({
    required this.productId,
    required this.productName,
    required this.quantityDelta,
    required this.unitPrice,
    required this.unitCostSnapshot,
    required this.lineGross,
    required this.lineCost,
    this.batchId,
    this.batchCode,
    this.sortOrder = 0,
  });

  factory ResolvedLineModel.fromJson(Map<String, dynamic> json) =>
      _$ResolvedLineModelFromJson(json);

  final String productId;
  final String? batchId;
  final String? batchCode;
  final String productName;
  final String quantityDelta;
  final String unitPrice;
  final String unitCostSnapshot;
  final String lineGross;
  final String lineCost;
  final int sortOrder;

  ResolvedLine toEntity() => ResolvedLine(
    productId: productId,
    batchId: batchId,
    batchCode: batchCode,
    productName: productName,
    quantityDelta: Decimal.parse(quantityDelta),
    unitPrice: Decimal.parse(unitPrice),
    unitCostSnapshot: Decimal.parse(unitCostSnapshot),
    lineGross: Decimal.parse(lineGross),
    lineCost: Decimal.parse(lineCost),
    sortOrder: sortOrder,
  );
}

@JsonSerializable(createToJson: false)
class TransactionMoneyModel {
  const TransactionMoneyModel({
    required this.itemsSubtotal,
    required this.discountTotal,
    required this.buyerChargeTotal,
    required this.sellerCostTotal,
    required this.passThroughTotal,
    required this.buyerTotal,
    required this.netRevenue,
    required this.cogs,
    required this.grossProfit,
    required this.netProfit,
    required this.netMargin,
  });

  factory TransactionMoneyModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionMoneyModelFromJson(json);

  @JsonKey(name: 'items_subtotal')
  final String itemsSubtotal;
  @JsonKey(name: 'discount_total')
  final String discountTotal;
  @JsonKey(name: 'buyer_charge_total')
  final String buyerChargeTotal;
  @JsonKey(name: 'seller_cost_total')
  final String sellerCostTotal;
  @JsonKey(name: 'pass_through_total')
  final String passThroughTotal;
  @JsonKey(name: 'buyer_total')
  final String buyerTotal;
  @JsonKey(name: 'net_revenue')
  final String netRevenue;
  final String cogs;
  @JsonKey(name: 'gross_profit')
  final String grossProfit;
  @JsonKey(name: 'net_profit')
  final String netProfit;
  @JsonKey(name: 'net_margin')
  final String netMargin;

  TransactionMoney toEntity() => TransactionMoney(
    itemsSubtotal: Decimal.parse(itemsSubtotal),
    discountTotal: Decimal.parse(discountTotal),
    buyerChargeTotal: Decimal.parse(buyerChargeTotal),
    sellerCostTotal: Decimal.parse(sellerCostTotal),
    passThroughTotal: Decimal.parse(passThroughTotal),
    buyerTotal: Decimal.parse(buyerTotal),
    netRevenue: Decimal.parse(netRevenue),
    cogs: Decimal.parse(cogs),
    grossProfit: Decimal.parse(grossProfit),
    netProfit: Decimal.parse(netProfit),
    netMargin: Decimal.parse(netMargin),
  );
}

@JsonSerializable(createToJson: false)
class TransactionPreviewModel {
  const TransactionPreviewModel({
    required this.storeId,
    required this.type,
    required this.currencyMinorUnits,
    required this.money,
    this.lines = const [],
  });

  factory TransactionPreviewModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionPreviewModelFromJson(json);

  final String storeId;
  final String type;
  final int currencyMinorUnits;
  final TransactionMoneyModel money;
  final List<ResolvedLineModel> lines;

  TransactionPreview toEntity() => TransactionPreview(
    storeId: storeId,
    type: TransactionTypeX.fromWire(type),
    currencyMinorUnits: currencyMinorUnits,
    money: money.toEntity(),
    lines: lines.map((line) => line.toEntity()).toList(),
  );
}

@JsonSerializable(createToJson: false)
class FeePresetModel {
  const FeePresetModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.direction,
    required this.kind,
    required this.value,
    this.isPassThrough = false,
    this.isDefault = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory FeePresetModel.fromJson(Map<String, dynamic> json) =>
      _$FeePresetModelFromJson(json);

  final String id;
  @JsonKey(name: 'store_id')
  final String storeId;
  final String name;
  final String direction;
  final String kind;
  final String value;
  @JsonKey(name: 'is_pass_through')
  final bool isPassThrough;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'deleted_at')
  final String? deletedAt;

  FeePreset toEntity() => FeePreset(
    id: id,
    storeId: storeId,
    name: name,
    direction: feeDirectionFromWire(direction, isPassThrough: isPassThrough),
    kind: feeKindFromWire(kind),
    value: Decimal.parse(value),
    isDefault: isDefault,
    sortOrder: sortOrder,
    createdTime: createdAt == null ? null : DateTime.parse(createdAt!),
    updatedTime: updatedAt == null ? null : DateTime.parse(updatedAt!),
    deletedTime: deletedAt == null ? null : DateTime.parse(deletedAt!),
  );
}
