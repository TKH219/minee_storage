import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/onboarding/profile/states/profile_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/avatar_picker.dart';

class ProfilePage extends BasePage {
  const ProfilePage({super.key, this.imagePicker});

  /// Injected so widget tests never reach a platform channel.
  final ImagePicker? imagePicker;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends BasePageState<ProfilePage, ProfileState, ProfileStateNotifier> {
  /// Set here, not in [buildPageContent]: BasePageState reads `canPopPage`
  /// when it builds the PopScope, which happens before the page body runs.
  @override
  void initState() {
    super.initState();
    canPopPage = false;
  }

  @override
  void setCurrentState() => currentState = ref.watch(profileStateProvider);

  @override
  void setNotifier() => notifier = ref.read(profileStateProvider.notifier);

  @override
  Widget buildPageContent(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.onboarding_profile_title.tr(),
                style: context.textStyles.sansTitleHeading1,
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.onboarding_profile_subtitle.tr(),
                style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6),
              ),
              const SizedBox(height: 32),
              _buildAvatar(context),
              const SizedBox(height: 32),
              AppTextField(
                label: LocaleKeys.onboarding_profile_fullName.tr(),
                hint: LocaleKeys.onboarding_profile_fullNameHint.tr(),
                helperText: LocaleKeys.onboarding_profile_required.tr(),
                onChanged: notifier.updateFullName,
              ),
              if (currentState.isError && currentState.errorMessageKey != null) ...[
                const SizedBox(height: 16),
                Text(
                  currentState.errorMessage ?? currentState.errorMessageKey!.tr(),
                  style: context.textStyles.sansBody.copyWith(color: context.colors.red5),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: currentState.canSubmit ? notifier.submit : null,
                child: Text(LocaleKeys.onboarding_profile_continueLabel.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Column(
      children: [
        AvatarPicker(
          initials: currentState.initialsFor(''),
          imageUrl: currentState.avatarUrl,
          isUploading: currentState.isUploading,
          onPick: _pickAvatar,
        ),
        const SizedBox(height: 8),
        Text(
          currentState.isUploading
              ? LocaleKeys.onboarding_profile_uploading.tr()
              : LocaleKeys.onboarding_profile_addPhoto.tr(),
          style: context.textStyles.sansCaption.copyWith(color: context.colors.inkPrimary),
        ),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    final picker = widget.imagePicker ?? ImagePicker();
    // The downscale happens here, so nothing oversized ever leaves the device.
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;

    await notifier.pickedAvatar(
      bytes: await file.readAsBytes(),
      fileExtension: file.name.split('.').last,
    );
  }
}
