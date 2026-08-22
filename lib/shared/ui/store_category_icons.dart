import 'package:flutter/material.dart';

/// `store_categories.icon` holds an opaque token rather than an icon name, so
/// a category added to the database after this build still renders.
const Map<String, IconData> _icons = {
  'basket': Icons.shopping_basket_outlined,
  'storefront': Icons.storefront_outlined,
  'restaurant': Icons.restaurant_outlined,
  'cafe': Icons.local_cafe_outlined,
  'food_court': Icons.dinner_dining_outlined,
  'warehouse': Icons.warehouse_outlined,
  'apparel': Icons.checkroom_outlined,
  'cosmetics': Icons.spa_outlined,
  'pharmacy': Icons.medical_services_outlined,
  'electronics': Icons.devices_outlined,
  'stationery': Icons.menu_book_outlined,
  'online': Icons.shopping_cart_outlined,
  'other': Icons.more_horiz_outlined,
};

IconData iconForCategory(String token) => _icons[token] ?? _icons['other']!;
