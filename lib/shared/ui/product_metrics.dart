import 'package:flutter/widgets.dart';

/// Shared row geometry so a skeleton row and a loaded row are the same shape
/// and nothing reflows when the real data arrives.
abstract class ProductRowMetrics {
  static const EdgeInsets padding = EdgeInsets.symmetric(vertical: 12, horizontal: 16);
  static const double thumbSize = 56;
  static const double gap = 12;
  static const double innerGap = 3;
  static const double nameSize = 15;
  static const double priceSize = 13;
}
