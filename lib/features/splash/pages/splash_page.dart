import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/splash/states/splash_state.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.neutral0,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.tintPrimary,
                borderRadius: BorderRadius.circular(11.8),
              ),
              child: Icon(Icons.inventory_2_rounded, size: 30, color: colors.primary4),
            ),
            const SizedBox(height: 16),
            Text(LocaleKeys.splash_appName.tr(), style: context.textStyles.sansTitleHeading2),
            Text(
              LocaleKeys.splash_tagline.tr(),
              style: context.textStyles.sansBody.copyWith(color: colors.neutral6),
            ),
            const SizedBox(height: 24),
            const LottieAnimation(name: 'spinner', size: 48),
          ],
        ),
      ),
    );
  }
}
