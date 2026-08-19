import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(title: const Text('Reports')),
      body: const EmptyView(
        icon: Icons.bar_chart_rounded,
        title: 'Nothing to report yet',
        subtitle: "Once you've recorded a few purchases and used some stock, "
            'your movement and spend summaries will show up here.',
      ),
    );
  }
}
