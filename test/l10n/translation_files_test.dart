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
    // Inspects the parsed values rather than searching the raw text for `""`:
    // a legitimate value carrying a quoted word — `No matches for "milk"` —
    // contains that sequence once escaped, and blank-but-not-empty values slip
    // past a substring check entirely.
    for (final locale in ['en', 'vi']) {
      final raw = File('assets/translations/$locale.json').readAsStringSync();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final blank = <String>[];
      void walk(Map<String, dynamic> node, String path) {
        node.forEach((key, value) {
          final here = path.isEmpty ? key : '$path.$key';
          if (value is Map<String, dynamic>) {
            walk(value, here);
          } else if (value is String && value.trim().isEmpty) {
            blank.add(here);
          }
        });
      }

      walk(decoded, '');
      expect(blank, isEmpty, reason: '$locale.json leaves these empty: $blank');
    }
  });
}
