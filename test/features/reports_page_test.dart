import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/reports/pages/reports_page.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';

void main() {
  testWidgets('renders the Report placeholder', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _Harness(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report'), findsOneWidget);
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('No reports yet'), findsOneWidget);
  });
}

class _Harness extends StatelessWidget {
  const _Harness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: const ReportsPage(),
    );
  }
}
