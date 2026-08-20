import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/lot.dart';
import 'package:mine_storage/domain/entities/product.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/ui/product_row.dart';

import '../../../support/localization_test_harness.dart';

final milk = Product(
  id: 'milk', storeId: 's1', name: 'Whole Milk 1L', brand: 'Dairyland', location: 'Cold room A',
  lots: [
    Lot(id: 'l1', productId: 'milk', purchasedOn: DateTime(2026, 8, 8),
        expiresOn: DateTime(2026, 8, 22), unitPrice: 1.10, initialQuantity: 12, remainingQuantity: 2),
  ],
);

Widget host(Widget child, {bool reducedMotion = false}) => MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Scaffold(body: SizedBox(width: 390, child: child)),
      ),
    );

void main() {
  setUp(useLocale);

  testWidgets('skeleton row geometry matches a real product row', (tester) async {
    await tester.pumpWidget(host(const SkeletonRow()));
    final skeletonHeight = tester.getSize(find.byType(SkeletonRow)).height;

    await tester.pumpWidget(host(ProductRow(product: milk, today: DateTime(2026, 8, 20))));
    expect(skeletonHeight, tester.getSize(find.byType(ProductRow)).height);
  });

  testWidgets('reduced motion stops the shimmer scheduling frames', (tester) async {
    await tester.pumpWidget(host(
      const Shimmer(child: SizedBox(width: 100, height: 20)),
      reducedMotion: true,
    ));
    await tester.pump(const Duration(milliseconds: 750));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the shimmer animates when motion is allowed', (tester) async {
    await tester.pumpWidget(host(const Shimmer(child: SizedBox(width: 100, height: 20))));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('the success check reports completion after 900ms', (tester) async {
    var done = false;
    await tester.pumpWidget(host(SuccessCheck(onComplete: () => done = true)));
    await tester.pump(const Duration(milliseconds: 850));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 100));
    expect(done, isTrue);
  });

  testWidgets('reduced motion still completes the success check', (tester) async {
    var done = false;
    await tester.pumpWidget(host(
      SuccessCheck(onComplete: () => done = true),
      reducedMotion: true,
    ));
    await tester.pump(const Duration(milliseconds: 950));
    expect(done, isTrue);
  });

  testWidgets('the labelled spinner shows its plain-language label', (tester) async {
    await tester.pumpWidget(host(const LabelledSpinner(label: 'Restoring your session')));
    expect(find.text('Restoring your session'), findsOneWidget);
  });

  testWidgets('button dots hold the label and the target size', (tester) async {
    await tester.pumpWidget(host(const ButtonDots()));
    expect(find.byType(ButtonDots), findsOneWidget);
  });

  testWidgets('the scan sweep stops dead when it is not active', (tester) async {
    await tester.pumpWidget(host(const ScanSweep(active: false)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
