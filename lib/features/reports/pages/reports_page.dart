import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/shared/ui/empty_view.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: const SafeArea(
        child: EmptyView(
          icon: Icons.insert_chart_outlined_rounded,
          title: 'No reports yet',
          subtitle: 'Reports and statistics will appear here.',
        ),
      ),
    );
  }
}
