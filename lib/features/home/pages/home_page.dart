import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/home/states/home_state.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/theme_mode_button.dart';

class HomePage extends BasePage {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BasePageState<HomePage, HomeState, HomeStateNotifier> {
  @override
  void setCurrentState() => currentState = ref.watch(homeStateProvider);

  @override
  void setNotifier() => notifier = ref.read(homeStateProvider.notifier);

  @override
  Widget buildPageContent(BuildContext context) {
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
