import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(title: const Text('Products')),
      body: const EmptyView(
        icon: Icons.inventory_2_outlined,
        title: 'Your shelves are empty',
        subtitle: 'Add your first product, or scan a barcode to start counting what you hold.',
      ),
    );
  }
}
