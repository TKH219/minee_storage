import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/create_store/states/create_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_option_sheet.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/avatar_picker.dart';
import 'package:mine_storage/shared/ui/store_category_icons.dart';

class CreateStorePage extends BasePage {
  const CreateStorePage({super.key, this.imagePicker});

  /// Injected so widget tests never reach a platform channel.
  final ImagePicker? imagePicker;

  @override
  ConsumerState<CreateStorePage> createState() => _CreateStorePageState();
}

class _CreateStorePageState
    extends BasePageState<CreateStorePage, CreateStoreState, CreateStoreStateNotifier> {
  /// Set here, not in [buildPageContent]: BasePageState reads `canPopPage`
  /// when it builds the PopScope, which happens before the page body runs.
  @override
  void initState() {
    super.initState();
    canPopPage = false;
  }

  @override
  void setCurrentState() => currentState = ref.watch(createStoreStateProvider);

  @override
  void setNotifier() => notifier = ref.read(createStoreStateProvider.notifier);

  @override
  void initDataFromConstructor() => notifier.loadCategories();

  @override
  Widget buildPageContent(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      LocaleKeys.onboarding_store_title.tr(),
                      style: context.textStyles.sansTitleHeading1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocaleKeys.onboarding_store_subtitle.tr(),
                      style: context.textStyles.sansBody
                          .copyWith(color: context.colors.neutral6),
                    ),
                    const SizedBox(height: 32),
                    _buildLogo(context),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: LocaleKeys.onboarding_store_name.tr(),
                      hint: LocaleKeys.onboarding_store_nameHint.tr(),
                      onChanged: notifier.updateName,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPickerRow(
                context,
                label: LocaleKeys.onboarding_store_category.tr(),
                value: currentState.category?.localisedName(Localizations.localeOf(context).languageCode) ??
                    LocaleKeys.onboarding_store_categoryPrompt.tr(),
                onTap: _pickCategory,
              ),
              _buildPickerRow(
                context,
                label: LocaleKeys.onboarding_store_currency.tr(),
                value: '${currentState.displayCurrency.code}  ${currentState.displayCurrency.symbol}',
                onTap: _pickCurrency,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: '${LocaleKeys.onboarding_store_address.tr()} '
                          '(${LocaleKeys.onboarding_store_optional.tr()})',
                      hint: LocaleKeys.onboarding_store_addressHint.tr(),
                      onChanged: notifier.updateAddress,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: '${LocaleKeys.onboarding_store_url.tr()} '
                          '(${LocaleKeys.onboarding_store_optional.tr()})',
                      hint: LocaleKeys.onboarding_store_urlHint.tr(),
                      helperText: LocaleKeys.onboarding_store_urlHelp.tr(),
                      errorText: currentState.urlIsInvalid
                          ? LocaleKeys.onboarding_store_urlInvalid.tr()
                          : null,
                      keyboardType: TextInputType.url,
                      onChanged: notifier.updateUrl,
                    ),
                    if (currentState.isError && currentState.errorMessageKey != null) ...[
                      const SizedBox(height: 16),
                      _buildLoadError(context),
                    ],
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: currentState.canSubmit ? notifier.submit : null,
                      child: Text(LocaleKeys.onboarding_store_create.tr()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadError(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            currentState.errorMessage ?? currentState.errorMessageKey!.tr(),
            style: context.textStyles.sansBody.copyWith(color: context.colors.red5),
          ),
        ),
        if (currentState.categories.isEmpty)
          TextButton(
            onPressed: notifier.loadCategories,
            child: Text(LocaleKeys.onboarding_store_retry.tr()),
          ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Row(
      children: [
        AvatarPicker(
          initials: '',
          imageUrl: currentState.logoUrl,
          isUploading: currentState.isUploading,
          shape: AvatarPickerShape.rounded,
          onPick: _pickLogo,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.onboarding_store_logo.tr(),
                style: context.textStyles.sansBodyBold
                    .copyWith(color: context.colors.neutral9),
              ),
              Text(
                LocaleKeys.onboarding_store_optional.tr(),
                style: context.textStyles.sansCaption
                    .copyWith(color: context.colors.neutral6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickerRow(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.neutral2)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: context.textStyles.sansBody.copyWith(color: colors.neutral9),
            ),
            const SizedBox(width: 16),
            // The value takes what is left: a long category name in Vietnamese
            // would otherwise push the chevron off the row.
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 20, color: colors.neutral4),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final code = await showAppOptionSheet<String>(
      context: context,
      title: LocaleKeys.onboarding_store_categoryTitle.tr(),
      selected: currentState.categoryCode,
      options: [
        for (final category in currentState.categories)
          AppOption(
            value: category.code,
            label: category.localisedName(Localizations.localeOf(context).languageCode),
            icon: iconForCategory(category.icon),
          ),
      ],
    );
    if (code != null) notifier.updateCategory(code);
  }

  Future<void> _pickCurrency() async {
    final currency = await showAppOptionSheet<Currency>(
      context: context,
      title: LocaleKeys.onboarding_store_currencyTitle.tr(),
      selected: currentState.currency,
      options: [
        for (final currency in currentState.currencies)
          AppOption(value: currency, label: '${currency.code}  ${currency.symbol}'),
      ],
    );
    if (currency != null) notifier.updateCurrency(currency);
  }

  Future<void> _pickLogo() async {
    final picker = widget.imagePicker ?? ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;

    await notifier.pickedLogo(
      bytes: await file.readAsBytes(),
      fileExtension: file.name.split('.').last,
    );
  }
}
