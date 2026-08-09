import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/theme_mode_button.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [ThemeModeButton()],
      ),
      body: const SafeArea(
        child: EmptyView(
          icon: Icons.home_rounded,
          title: 'Home is not built yet',
          subtitle: 'Your inventory will live here.',
        ),
      ),
    );
  }
}
