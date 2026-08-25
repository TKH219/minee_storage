import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/settings/states/settings_state.dart';

import 'expiry_badge.dart';
import 'product_metrics.dart';
import 'quantity_format.dart';

class ProductRow extends ConsumerWidget {
  const ProductRow({
    super.key,
    required this.product,
    required this.today,
    this.onTap,
  });

  final ProductEntity product;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.textStyles;
    final money = ref.watch(currencyFormatterProvider);
    // Where the stock sits is a property of the delivery, so the sub line
    // names the location of the batch that will go out next.
    final location = product.availableBatches.isEmpty
        ? null
        : product.availableBatches.first.storageLocation;
    final subtitle = [product.brand, location].whereType<String>().join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        key: const Key('product-row-padding'),
        padding: ProductRowMetrics.padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              key: const Key('product-row-thumb'),
              width: ProductRowMetrics.thumbSize,
              height: ProductRowMetrics.thumbSize,
              decoration: BoxDecoration(
                color: colors.neutral2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.inventory_2_outlined, color: colors.neutral5, size: 24),
            ),
            const SizedBox(width: ProductRowMetrics.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: texts.sansBodyBold.copyWith(
                            fontSize: ProductRowMetrics.nameSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.latestUnitPrice != null)
                        Text(
                          money.format(product.latestUnitPrice!),
                          style: texts.monoBody.copyWith(
                            fontSize: ProductRowMetrics.priceSize,
                            color: colors.neutral7,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: ProductRowMetrics.innerGap),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: texts.sansCaption.copyWith(color: colors.neutral6),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        formatQuantity(product.totalRemaining),
                        style: texts.monoBody.copyWith(
                          fontSize: ProductRowMetrics.priceSize,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ExpiryBadge(
                          status: product.statusOn(today),
                          expiry: product.nearestExpiry,
                          today: today,
                          archived: product.archived,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
