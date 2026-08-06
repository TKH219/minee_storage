import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';

/// Cycles System → Light → Dark and reports the new mode in a tooltip.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return IconButton(
      tooltip: 'Theme: ${mode.label}',
      icon: Icon(mode.icon),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}
