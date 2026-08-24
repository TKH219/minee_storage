import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

import '../widgets/language_picker_sheet.dart';
import '../widgets/settings_metrics.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: colors.neutral1,
      appBar: AppBar(
        leading: BackButton(onPressed: () => _leaveSettings(context)),
        title: Text(LocaleKeys.settings_title.tr()),
      ),
      body: ListView(
        children: [
          Padding(
            padding: SettingsMetrics.sectionPadding,
            child: Text(
              LocaleKeys.settings_preferences.tr(),
              style: context.textStyles.sansCaption.copyWith(
                fontSize: SettingsMetrics.sectionLabelSize,
                color: colors.neutral6,
              ),
            ),
          ),
          ColoredBox(
            color: colors.neutral0,
            child: Column(
              children: [
                SettingsTile(
                  icon: themeMode.icon,
                  label: LocaleKeys.settings_theme.tr(),
                  value: themeMode.labelKey.tr(),
                  onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                ),
                Divider(
                  height: SettingsMetrics.dividerThickness,
                  thickness: SettingsMetrics.dividerThickness,
                  color: colors.neutral2,
                ),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  label: LocaleKeys.settings_language.tr(),
                  value: _endonymFor(context.locale),
                  onTap: () => showLanguagePicker(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
