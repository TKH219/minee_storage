import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/splash/states/splash_state.dart';

class SplashPage extends BasePage {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends BasePageState<SplashPage, SplashState, SplashStateNotifier> {
  @override
  void initState() {
    // The splash screen is its own loading treatment.
    allowToShowLoading = false;
    super.initState();
  }

  @override
  void setCurrentState() => currentState = ref.watch(splashStateProvider);

  @override
  void setNotifier() => notifier = ref.read(splashStateProvider.notifier);

  @override
  void initDataFromConstructor() => notifier.bootstrap();

  @override
  Widget buildPageContent(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary4,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_rounded,
              size: 72,
              color: context.colors.isDark ? context.colors.neutral0 : context.colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              'Mine Storage',
              style: context.textStyles.sansTitleHeading2.copyWith(
                color: context.colors.isDark ? context.colors.neutral0 : context.colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
