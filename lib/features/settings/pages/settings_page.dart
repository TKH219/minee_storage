import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/app_snack.dart';
import 'package:mine_storage/shared/ui/coming_soon.dart';

import '../states/settings_state.dart';
import '../widgets/currency_picker_sheet.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/settings_metrics.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_picker_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: colors.neutral1,
      appBar: AppBar(
        leading: BackButton(onPressed: () => _leaveSettings(context)),
        title: Text(LocaleKeys.settings_title.tr()),
      ),
      body: ListView(
        children: [
          _buildProfileHeader(ref),
          _group(context, [
            SettingsTile(
              icon: Icons.person_outline_rounded,
              label: LocaleKeys.settings_myProfile.tr(),
              onTap: showComingSoon,
            ),
            SettingsTile(
              icon: Icons.lock_outline_rounded,
              label: LocaleKeys.settings_changePassword.tr(),
              onTap: showComingSoon,
            ),
            SettingsTile(
              key: const Key('settings-allow-updates'),
              icon: Icons.tune_rounded,
              label: LocaleKeys.settings_allowProfileUpdates.tr(),
              onTap: () => _toggleProfileUpdates(ref),
              trailing: SizedBox(
                width: SettingsMetrics.switchWidth,
                height: SettingsMetrics.switchHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch(
                    value: ref.watch(allowProfileUpdatesProvider),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (value) =>
                        ref.read(allowProfileUpdatesProvider.notifier).set(value),
                  ),
                ),
              ),
            ),
          ]),
          _sectionLabel(context, LocaleKeys.settings_preferences.tr()),
          _group(context, [
            SettingsTile(
              icon: Icons.payments_outlined,
              label: LocaleKeys.settings_currency.tr(),
              value: '${currency.code} ${currency.symbol}',
              onTap: () => _pickCurrency(context, ref, currency),
            ),
            SettingsTile(
              icon: themeMode.icon,
              label: LocaleKeys.settings_theme.tr(),
              value: themeMode.labelKey.tr(),
              onTap: () => _pickTheme(context, ref, themeMode),
            ),
            SettingsTile(
              icon: Icons.translate_rounded,
              label: LocaleKeys.settings_language.tr(),
              value: _endonymFor(context.locale),
              onTap: () => showLanguagePicker(context),
            ),
          ]),
          const SizedBox(height: SettingsMetrics.groupGap),
          _group(context, [
            SettingsTile(
              icon: Icons.logout_rounded,
              label: LocaleKeys.settings_logOut.tr(),
              destructive: true,
              onTap: () {},
            ),
          ]),
          const SizedBox(height: SettingsMetrics.groupGap),
        ],
      ),
    );
  }

  static Widget _buildProfileHeader(WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();
    return ProfileHeader(name: user.fullName, email: user.email);
  }

  static Widget _sectionLabel(BuildContext context, String label) => Padding(
    padding: SettingsMetrics.sectionPadding,
    child: Text(
      label,
      style: context.textStyles.sansCaption.copyWith(
        fontSize: SettingsMetrics.sectionLabelSize,
        color: context.colors.neutral6,
      ),
    ),
  );

  /// The design's grouped rows: a neutral0 block ruled top and bottom, sitting
  /// on the neutral1 page.
  static Widget _group(BuildContext context, List<Widget> tiles) {
    final colors = context.colors;
    final rule = BorderSide(
      color: colors.neutral2,
      width: SettingsMetrics.dividerThickness,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.neutral0,
        border: Border(top: rule, bottom: rule),
      ),
      child: Column(
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            if (index > 0)
              Divider(
                height: SettingsMetrics.dividerThickness,
                thickness: SettingsMetrics.dividerThickness,
                color: colors.neutral2,
              ),
            tiles[index],
          ],
        ],
      ),
    );
  }

  static Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode selected,
  ) async {
    final picked = await showThemePicker(context, selected: selected);
    if (picked == null) return;
    await ref.read(themeModeProvider.notifier).setThemeMode(picked);
  }

  static void _toggleProfileUpdates(WidgetRef ref) {
    final notifier = ref.read(allowProfileUpdatesProvider.notifier);
    notifier.set(!ref.read(allowProfileUpdatesProvider));
  }

  /// The list is read on tap rather than watched: the table changes about once
  /// a year, and a settings row must not sit empty waiting on the network.
  static Future<void> _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    Currency selected,
  ) async {
    final List<Currency> currencies;
    try {
      currencies = await ref.read(storeRepositoryProvider).currencies();
    } on Object {
      showErrorSnack(LocaleKeys.errors_generic.tr());
      return;
    }
    if (!context.mounted) return;

    final picked = await showCurrencyPicker(
      context,
      currencies: currencies,
      selected: selected,
    );
    if (picked == null) return;
    await ref.read(currencyProvider.notifier).setCurrency(picked);
  }

  /// The dashboard reaches settings with `go`, so there is usually nothing on
  /// the stack to pop back to.
  static void _leaveSettings(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.dashboardName);
    }
  }

  static String _endonymFor(Locale locale) {
    return kLanguageEndonyms.entries
        .firstWhere(
          (entry) => entry.value.languageCode == locale.languageCode,
          orElse: () => kLanguageEndonyms.entries.first,
        )
        .key;
  }
}
