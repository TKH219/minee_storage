import 'package:flutter_test/flutter_test.dart';


import '../support/transaction_fixtures.dart';

void main() {
  group('TransactionLine.countedQuantity', () {
    test('is what the shelf held plus the delta the server applied', () {
      final line = ledgerLine(quantityBefore: '12.000', quantityDelta: '-2.000');

      expect(line.countedQuantity, dec('10.000'));
    });

    test('is null when the holding was never recorded', () {
      final line = ledgerLine(quantityDelta: '-2.000');

      expect(line.quantityBefore, isNull);
      expect(line.countedQuantity, isNull);
    });

    test('follows a positive delta upward', () {
      final line = ledgerLine(quantityBefore: '8.000', quantityDelta: '3.000');

      expect(line.countedQuantity, dec('11.000'));
    });
  });
}
