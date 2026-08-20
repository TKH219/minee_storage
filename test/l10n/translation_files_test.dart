import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> flatten(Map<String, dynamic> node, [String prefix = '']) {
  final keys = <String>{};
  node.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      keys.addAll(flatten(value, path));
    } else {
      keys.add(path);
    }
  });
  return keys;
}

Set<String> load(String locale) {
  final raw = File('assets/translations/$locale.json').readAsStringSync();
  return flatten(jsonDecode(raw) as Map<String, dynamic>);
}

void main() {
  test('en and vi carry identical key sets', () {
    final en = load('en');
    final vi = load('vi');

    expect(en.difference(vi), isEmpty, reason: 'keys missing from vi.json');
    expect(vi.difference(en), isEmpty, reason: 'orphaned keys in vi.json');
    expect(en, isNotEmpty);
  });

  test('no translation value is left empty', () {
    for (final locale in ['en', 'vi']) {
      final raw = File('assets/translations/$locale.json').readAsStringSync();
      expect(raw.contains('""'), isFalse, reason: '$locale.json has an empty value');
    }
  });
}
