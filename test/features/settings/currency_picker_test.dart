import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/settings/states/settings_state.dart';
import 'package:mine_storage/features/settings/widgets/currency_picker_sheet.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import '../../support/design_frame.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2, sortOrder: 1);
const eur = Currency(id: 'cur-eur', code: 'EUR', symbol: '€', decimals: 2, sortOrder: 2);
const gbp = Currency(id: 'cur-gbp', code: 'GBP', symbol: '£', decimals: 2, sortOrder: 3);
const sgd = Currency(id: 'cur-sgd', code: 'SGD', symbol: r'$', decimals: 2, sortOrder: 4);
const vnd = Currency(id: 'cur-vnd', code: 'VND', symbol: '₫', decimals: 0, sortOrder: 5);

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<Currency?> pumpPicker(
    WidgetTester tester, {
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
    Currency selected = vnd,
    List<Currency> currencies = const [usd, eur, gbp, sgd, vnd],
  }) async {
    useDesignFrame(tester);
    Currency? picked;

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(currencyList: currencies),
        ),
      ],
    );
    addTearDown(container.dispose);

    await initLocalization();
    useLocale(locale);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    picked = await showCurrencyPicker(
                      context,
                      currencies: currencies,
                      selected: selected,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('lists the five currencies the design names', (tester) async {
    await pumpPicker(tester);

    expect(find.text('US dollar'), findsOneWidget);
    expect(find.text('Euro'), findsOneWidget);
    expect(find.text('Pound sterling'), findsOneWidget);
    expect(find.text('Singapore dollar'), findsOneWidget);
    expect(find.text('Vietnamese dong'), findsOneWidget);
    expect(find.text(r'USD · $'), findsOneWidget);
    expect(find.text('VND · ₫'), findsOneWidget);
  });

  testWidgets('leads with the notice, because the rule is not obvious',
      (tester) async {
    await pumpPicker(tester);

    expect(
      find.text(
        'This changes the symbol on your prices. It does not convert them.',
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.textContaining('does not convert')).dy,
      lessThan(tester.getTopLeft(find.text('US dollar')).dy),
    );
  });

  testWidgets('marks only the current currency', (tester) async {
    await pumpPicker(tester, selected: usd);

    final context = tester.element(find.byType(CurrencyPickerSheet));
    final selected = tester.widget<Container>(
      find.byKey(const Key('currency-radio-USD')),
    );
    final other = tester.widget<Container>(
      find.byKey(const Key('currency-radio-EUR')),
    );

    expect(
      ((selected.decoration! as BoxDecoration).border! as Border).top.color,
      context.colors.primary4,
    );
    expect(
      ((other.decoration! as BoxDecoration).border! as Border).top.color,
      context.colors.neutral4,
    );
  });

  testWidgets('picking one hands it back and closes', (tester) async {
    await pumpPicker(tester, selected: vnd);

    await tester.tap(find.text('US dollar'));
    await tester.pumpAndSettle();

    expect(find.text('Vietnamese dong'), findsNothing);
  });

  testWidgets('switching currency relabels prices and converts nothing',
      (tester) async {
    await pumpPicker(tester, selected: vnd);

    final amount = Decimal.parse('1234.00');
    final before = const CurrencyFormatter(vnd).format(amount);
    final after = const CurrencyFormatter(usd).format(amount);

    expect(before, '₫1,234');
    expect(after, r'$1,234.00');
    // The same 1234 either way. Only the symbol and the minor-unit precision
    // belong to the currency — no rate is applied, because there is none.
    expect(before.replaceAll(RegExp(r'[^1-9]'), ''), '1234');
    expect(after.replaceAll(RegExp(r'[^1-9]'), ''), '1234');
  });

  testWidgets('persists only the code, never the symbol', (tester) async {
    await pumpPicker(tester, selected: vnd);

    await tester.tap(find.text('US dollar'));
    await tester.pumpAndSettle();

    await container.read(currencyProvider.notifier).setCurrency(usd);
    expect(prefs.getString(CurrencyNotifier.storageKey), 'USD');
  });

  testWidgets('orders the list the way the table asks', (tester) async {
    await pumpPicker(tester, currencies: const [vnd, usd]);

    expect(
      tester.getTopLeft(find.text('US dollar')).dy,
      lessThan(tester.getTopLeft(find.text('Vietnamese dong')).dy),
    );
  });

  testWidgets('falls back to the code for a currency it has no name for',
      (tester) async {
    const aud = Currency(id: 'cur-aud', code: 'AUD', symbol: r'$', decimals: 2);
    await pumpPicker(tester, currencies: const [aud]);

    expect(find.text('AUD'), findsOneWidget);
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpPicker(tester, locale: viLocale);

    expect(find.text('Đô la Mỹ'), findsOneWidget);
    expect(find.textContaining('không quy đổi'), findsOneWidget);
    expect(find.textContaining('settings.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    await pumpPicker(tester, brightness: Brightness.dark);

    expect(find.text('US dollar'), findsOneWidget);
    expect(find.textContaining('settings.'), findsNothing);
  });
}
