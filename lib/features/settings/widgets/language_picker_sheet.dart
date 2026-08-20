import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

import 'settings_metrics.dart';

/// The supported languages, named in their own language.
///
/// Endonyms are deliberately not translated: someone who has landed in a
/// language they cannot read still needs to recognise their own.
const Map<String, Locale> kLanguageEndonyms = {
  'English': Locale('en'),
  'Tiếng Việt': Locale('vi'),
};

Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.neutral0,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: SettingsMetrics.sectionPadding,
            child: Text(
              LocaleKeys.settings_language.tr(),
              style: sheetContext.textStyles.sansBodyBold,
            ),
          ),
          for (final entry in kLanguageEndonyms.entries)
            InkWell(
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await context.setLocale(entry.value);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: SettingsMetrics.tileMinHeight),
                child: Padding(
                  padding: SettingsMetrics.tilePadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: sheetContext.textStyles.sansBody.copyWith(
                            fontSize: SettingsMetrics.labelSize,
                          ),
                        ),
                      ),
                      if (context.locale == entry.value)
                        Icon(Icons.check_rounded, color: sheetContext.colors.primary4),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
