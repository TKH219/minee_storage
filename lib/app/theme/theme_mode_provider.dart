import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/shared/utils/logger.dart';

import 'package:mine_storage/l10n/locale_keys.g.dart';

/// Overridden in `main()` once [SharedPreferences] has been opened.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Tri-state theme selection persisted across launches.
///
/// [ThemeMode.system] is the default, so a fresh install follows the OS.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String storageKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    return _decode(stored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      await ref.read(sharedPreferencesProvider).setString(storageKey, mode.name);
    } on Exception catch (e) {
      logger.e('Failed to persist theme mode', error: e);
    }
  }

  /// Cycles system → light → dark → system, for a single-tap app bar control.
  Future<void> toggle() {
    return setThemeMode(switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    });
  }

  static ThemeMode _decode(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

extension ThemeModeLabel on ThemeMode {
  /// A key, not a resolved string, so switching language retranslates the
  /// label already on screen.
  String get labelKey => switch (this) {
    ThemeMode.system => LocaleKeys.settings_themeSystem,
    ThemeMode.light => LocaleKeys.settings_themeLight,
    ThemeMode.dark => LocaleKeys.settings_themeDark,
  };

  IconData get icon => switch (this) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };
}
