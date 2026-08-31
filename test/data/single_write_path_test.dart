import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Exactly one write path into `batches.quantity_remaining`, enforced at the
/// server and not only on the device. The reasonless `apply_consumption` RPC
/// and the route that called it lost their last caller when the ledger took
/// over, and a second write path left standing is one a future caller can find.
void main() {
  final root = Directory.current.path;

  test('no Dart caller reaches for a consumption', () {
    final offenders = <String>[];
    for (final entity in Directory('$root/lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('consumptions') || source.contains('apply_consumption')) {
        offenders.add(entity.path);
      }
    }

    expect(offenders, isEmpty);
  });

  test('the products Edge Function serves no consumptions route', () {
    final source = File(
      '$root/supabase/functions/products/index.ts',
    ).readAsStringSync();

    expect(source, isNot(contains('consumptions')));
    expect(source, isNot(contains('apply_consumption')));
  });

  test('a migration drops the RPC', () {
    final dropped = Directory('$root/supabase/migrations')
        .listSync()
        .whereType<File>()
        .any(
          (file) => file.readAsStringSync().contains(
            'drop function if exists public.apply_consumption',
          ),
        );

    expect(dropped, isTrue);
  });

  test('the contract describes no consumptions route', () {
    final source = File('$root/.ai/contracts/products-api.yaml').existsSync()
        ? File('$root/.ai/contracts/products-api.yaml').readAsStringSync()
        : '';

    expect(source, isNot(contains('consumptions')));
  });
}
