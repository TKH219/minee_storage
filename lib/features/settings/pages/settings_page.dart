import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/coming_soon_snack.dart';
import 'package:mine_storage/shared/ui/nav_metrics.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowUpdates = ref.watch(allowProfileUpdatesProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: kNavBarReservedSpace),
          children: [
            const _AccountHeader(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('My profile'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showComingSoonSnack(context, 'My profile'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  showComingSoonSnack(context, 'Changing your password'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.edit_outlined),
              title: const Text('Allow profile updates'),
              value: allowUpdates,
              onChanged: (value) =>
                  ref.read(allowProfileUpdatesProvider.notifier).state = value,
            ),
            ListTile(
              leading: Icon(themeMode.icon),
              title: const Text('Theme'),
              subtitle: Text(themeMode.label),
              onTap: () => ref.read(themeModeProvider.notifier).toggle(),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: context.colors.red5),
              title: Text(
                'Log out',
                style: context.textStyles.sansBodyBold.copyWith(
                  color: context.colors.red5,
                ),
              ),
              onTap: () => _confirmLogOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Log out',
              style: dialogContext.textStyles.sansBodyBold.copyWith(
                color: dialogContext.colors.red5,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    context.goNamed(AppRoutes.signInName);
  }
}

class _AccountHeader extends ConsumerWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: context.colors.neutral2,
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: context.colors.neutral5,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<UserEntity?>(
            future: ref.read(authRepositoryProvider).currentUser(),
            builder: (context, snapshot) {
              final id = snapshot.data?.id;
              return Text(
                id == null || id.isEmpty ? '—' : id,
                style: context.textStyles.sansBody.copyWith(
                  color: context.colors.neutral6,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
