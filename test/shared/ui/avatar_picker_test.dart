import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/avatar_picker.dart';

import '../../support/localization_test_harness.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  setUp(useLocale);

  testWidgets('shows initials until an image exists', (tester) async {
    await tester.pumpWidget(host(const AvatarPicker(initials: 'MC')));

    expect(find.text('MC'), findsOneWidget);
  });

  testWidgets('tapping requests a pick when idle', (tester) async {
    var picked = 0;
    await tester.pumpWidget(host(AvatarPicker(initials: 'MC', onPick: () => picked++)));

    await tester.tap(find.byType(AvatarPicker));
    await tester.pump();

    expect(picked, 1);
  });

  testWidgets('a pick is not offered while an upload is in flight', (tester) async {
    var picked = 0;
    await tester.pumpWidget(
      host(AvatarPicker(initials: 'MC', isUploading: true, onPick: () => picked++)),
    );

    await tester.tap(find.byType(AvatarPicker), warnIfMissed: false);
    await tester.pump();

    expect(picked, 0);
    expect(find.text('MC'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the circle is 88 across', (tester) async {
    await tester.pumpWidget(host(const AvatarPicker(initials: 'MC')));

    final size = tester.getSize(
      find.descendant(of: find.byType(AvatarPicker), matching: find.byType(Container)).first,
    );

    expect(size, const Size(88, 88));
  });

  testWidgets('the rounded shape is square, for a shop logo', (tester) async {
    await tester.pumpWidget(
      host(const AvatarPicker(initials: 'NG', shape: AvatarPickerShape.rounded)),
    );

    final size = tester.getSize(
      find.descendant(of: find.byType(AvatarPicker), matching: find.byType(Container)).first,
    );

    expect(size, const Size(64, 64));
  });

  testWidgets('renders in dark without throwing', (tester) async {
    await tester.pumpWidget(
      host(const AvatarPicker(initials: 'MC'), brightness: Brightness.dark),
    );

    expect(tester.takeException(), isNull);
  });
}
