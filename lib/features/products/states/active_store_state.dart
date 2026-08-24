import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';

/// The store products are read and written against.
///
/// Onboarding picks it and writes it; nothing in products can change it — the
/// store switcher is a later feature. Null means onboarding never settled on
/// one, which every products screen has to refuse rather than guess past.
final activeStoreProvider = Provider<String?>(
  (ref) => ref.watch(sharedPreferencesProvider).getString(OnboardingResolver.activeStoreKey),
);
