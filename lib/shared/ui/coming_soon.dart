import 'package:easy_localization/easy_localization.dart';

import 'package:mine_storage/l10n/locale_keys.g.dart';

import 'app_snack.dart';

/// The one handler behind every row this spec ships inert — Create invoice,
/// My profile, Change password. A later spec replaces exactly one call site
/// each rather than hunting for scattered stubs.
void showComingSoon() => showSuccessSnack(LocaleKeys.common_comingSoon.tr());
