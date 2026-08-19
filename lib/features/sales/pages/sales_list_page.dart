import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';

class SalesListPage extends StatelessWidget {
  const SalesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(title: const Text('Sales')),
      body: const EmptyView(
        icon: Icons.receipt_long_outlined,
        title: 'No sales yet',
        subtitle: 'Sales you record will appear here, newest first.',
      ),
    );
  }
}
