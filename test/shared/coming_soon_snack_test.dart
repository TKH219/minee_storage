import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/coming_soon_snack.dart';

void main() {
  testWidgets('shows a coming-soon message naming the feature', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showComingSoonSnack(context, 'Adding items'),
              child: const Text('tap me'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tap me'));
    await tester.pump();

    expect(find.text('Adding items is coming soon'), findsOneWidget);
  });

  testWidgets('replaces an existing snack rather than queueing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showComingSoonSnack(context, 'Adding items'),
              child: const Text('tap me'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tap me'));
    await tester.pump();
    await tester.tap(find.text('tap me'));
    await tester.pump();

    expect(find.text('Adding items is coming soon'), findsOneWidget);
  });
}
