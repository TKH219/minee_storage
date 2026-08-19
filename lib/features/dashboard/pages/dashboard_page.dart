import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(title: const Text('Northside · Main')),
      body: const EmptyView(
        icon: Icons.inventory_2_outlined,
        title: 'No stock yet',
        subtitle: 'Add your first product, then record what you bought and what it cost. '
            'Your numbers start the moment you make a sale.',
      ),
    );
  }
}
