import 'package:flutter/material.dart';

import 'package:mine_storage/shared/ui/product_metrics.dart';

import 'shimmer.dart';

/// Geometry is taken from [ProductRowMetrics] rather than restated, so a row of
/// skeletons and a row of real products are exactly the same shape and nothing
/// reflows when the data arrives.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ProductRowMetrics.padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer(
            child: Container(
              width: ProductRowMetrics.thumbSize,
              height: ProductRowMetrics.thumbSize,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: ProductRowMetrics.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(context, height: ProductRowMetrics.nameSize * 1.5, widthFactor: 0.6),
                const SizedBox(height: ProductRowMetrics.innerGap),
                _bar(context, height: 12 * 1.5, widthFactor: 0.45),
                const SizedBox(height: 5),
                _bar(context, height: 22, widthFactor: 0.5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, {required double height, required double widthFactor}) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Shimmer(
        child: Container(
          height: height,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
