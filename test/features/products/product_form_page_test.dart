import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/features/products/form/pages/product_form_page.dart';
import 'package:mine_storage/features/products/form/widgets/unit_picker_field.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';

import '../../support/fake_media_repository.dart';
import '../../support/localization_test_harness.dart';

void main() {
  late SharedPreferences preferences;
  late _RecordingRepository repository;

  setUp(() async {
    useLocale();
    SharedPreferences.setMockInitialValues({
      OnboardingResolver.activeStoreKey: 'store-a',
    });
    preferences = await SharedPreferences.getInstance();
    repository = _RecordingRepository();
  });

  Future<void> pump(WidgetTester tester, {String? productId}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          productRepositoryProvider.overrideWithValue(repository),
          mediaRepositoryProvider.overrideWithValue(FakeMediaRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: ProductFormPage(productId: productId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('draws the fields the design lists, and the unit picker', (tester) async {
    await pump(tester);

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('Brand'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.byType(UnitPickerField), findsOneWidget);
    expect(find.byKey(const Key('product-photo-slot')), findsOneWidget);
  });

  testWidgets('save is inactive until a name exists', (tester) async {
    await pump(tester);

    final save = find.widgetWithText(TextButton, 'Save');
    expect(tester.widget<TextButton>(save).onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(AppTextField, 'Name').first,
      'Olive oil',
    );
    await tester.pump();

    expect(tester.widget<TextButton>(save).onPressed, isNotNull);
  });

  testWidgets('saving sends a draft carrying the typed name', (tester) async {
    await pump(tester);

    await tester.enterText(
      find.widgetWithText(AppTextField, 'Name').first,
      'Olive oil',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.lastDraft?.name, 'Olive oil');
    expect(repository.lastStoreId, 'store-a');
  });

  testWidgets('the unit picker offers every unit and applies the choice', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('product-unit-field')));
    await tester.pumpAndSettle();

    expect(find.text('Kilogram'), findsOneWidget);
    expect(find.text('Litre'), findsOneWidget);

    await tester.tap(find.text('Litre').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(AppTextField, 'Name').first,
      'Olive oil',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.lastDraft?.unit, ProductUnit.litre);
  });

  testWidgets('editing opens with the product already in the fields', (tester) async {
    await pump(tester, productId: 'p1');

    expect(find.text('Edit product'), findsOneWidget);
    expect(find.text('Olive oil 1L'), findsOneWidget);

    // Archive sits at the bottom of edit, past the fold on a 390x844 screen.
    await tester.scrollUntilVisible(
      find.byKey(const Key('product-archive-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('product-archive-button')), findsOneWidget);
  });

  testWidgets('creating offers no archive, since there is nothing to archive', (tester) async {
    await pump(tester);

    expect(find.text('New product'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-archive-button')), findsNothing);
  });
}

class _RecordingRepository extends FakeProductRepository {
  _RecordingRepository() : super(latency: Duration.zero);

  ProductDraft? lastDraft;
  String? lastStoreId;

  @override
  Future<ProductEntity> createProduct(
    ProductDraft draft, {
    required String storeId,
  }) {
    lastDraft = draft;
    lastStoreId = storeId;
    return super.createProduct(draft, storeId: storeId);
  }
}
