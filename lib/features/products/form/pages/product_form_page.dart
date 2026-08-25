import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/products/form/states/product_form_state.dart';
import 'package:mine_storage/features/products/form/widgets/unit_picker_field.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';

/// The design's field geometry, measured from `#form` (3321:14870).
abstract class ProductFormMetrics {
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 16, 16, 24);
  static const double fieldGap = 16;
  static const double photoHeight = 132;
  static const double pairGap = 10;
  static const double buttonHeight = 52;
}

class ProductFormPage extends BasePage {
  const ProductFormPage({super.key, this.productId, this.initialBarcode});

  /// Null creates; non-null edits.
  final String? productId;

  /// Set when a scan missed, so the one thing already known is not retyped.
  final String? initialBarcode;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState
    extends BasePageState<ProductFormPage, ProductFormState, ProductFormStateNotifier> {
  final _name = TextEditingController();
  final _barcode = TextEditingController();
  final _brand = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    for (final controller in [_name, _barcode, _brand, _category, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void setCurrentState() => currentState = ref.watch(productFormStateProvider);

  @override
  void setNotifier() => notifier = ref.read(productFormStateProvider.notifier);

  @override
  void initDataFromConstructor() {
    notifier.loadCategories();
    if (widget.productId != null) {
      notifier.loadForEdit(widget.productId!).then((_) => _syncControllers());
    } else if (widget.initialBarcode != null) {
      notifier.updateBarcode(widget.initialBarcode!);
      _barcode.text = widget.initialBarcode!;
    }
  }

  /// Only edit prefills need this — the controllers are the source of truth
  /// while typing, so writing to them on every rebuild would fight the cursor.
  ///
  /// Reads the provider rather than `currentState`, which is only refreshed
  /// during build and is therefore still pre-load when the fetch completes.
  void _syncControllers() {
    if (!mounted) return;
    final loaded = ref.read(productFormStateProvider);
    _name.text = loaded.name;
    _barcode.text = loaded.barcode;
    _brand.text = loaded.brand;
    _category.text = loaded.category;
    _notes.text = loaded.notes;
  }

  Future<void> _save() async {
    await notifier.submit();
    if (!mounted) return;
    final saved = ref.read(productFormStateProvider).savedProductId;
    if (saved != null) Navigator.of(context).maybePop(saved);
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.products_archiveProduct.tr()),
        content: Text(LocaleKeys.products_archiveConfirm.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LocaleKeys.common_cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(LocaleKeys.products_archiveProduct.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await notifier.archive();
    if (!mounted) return;
    Navigator.of(context).maybePop(widget.productId);
  }

  @override
  Widget buildPageContent(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.neutral1,
      appBar: AppBar(
        title: Text(
          (currentState.isEditing
                  ? LocaleKeys.products_editTitle
                  : LocaleKeys.products_newTitle)
              .tr(),
        ),
        actions: [
          TextButton(
            onPressed: currentState.canSubmit ? _save : null,
            child: Text(LocaleKeys.products_save.tr()),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: ProductFormMetrics.pagePadding,
          children: [
            _PhotoSlot(
              url: currentState.photoUrl,
              isUploading: currentState.isUploading,
            ),
            const SizedBox(height: ProductFormMetrics.fieldGap),
            AppTextField(
              label: LocaleKeys.products_name.tr(),
              hint: LocaleKeys.products_namePlaceholder.tr(),
              controller: _name,
              onChanged: notifier.updateName,
              errorText: currentState.isError && currentState.name.trim().isEmpty
                  ? LocaleKeys.products_nameRequired.tr()
                  : null,
            ),
            const SizedBox(height: ProductFormMetrics.fieldGap),
            AppTextField(
              label: LocaleKeys.products_barcode.tr(),
              hint: LocaleKeys.products_barcodePlaceholder.tr(),
              controller: _barcode,
              onChanged: notifier.updateBarcode,
              errorText: currentState.barcodeConflictName == null
                  ? null
                  : LocaleKeys.products_barcodeTaken.tr(),
              helperText: currentState.barcodeConflictName,
            ),
            const SizedBox(height: ProductFormMetrics.fieldGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: LocaleKeys.products_brand.tr(),
                    hint: LocaleKeys.products_optional.tr(),
                    controller: _brand,
                    onChanged: notifier.updateBrand,
                  ),
                ),
                const SizedBox(width: ProductFormMetrics.pairGap),
                Expanded(
                  child: AppTextField(
                    label: LocaleKeys.products_category.tr(),
                    hint: LocaleKeys.products_optional.tr(),
                    controller: _category,
                    onChanged: notifier.updateCategory,
                  ),
                ),
              ],
            ),
            _CategorySuggestions(
              suggestions: currentState.categorySuggestions,
              onPick: (value) {
                _category.text = value;
                notifier.updateCategory(value);
              },
            ),
            const SizedBox(height: ProductFormMetrics.fieldGap),
            UnitPickerField(value: currentState.unit, onChanged: notifier.updateUnit),
            const SizedBox(height: ProductFormMetrics.fieldGap),
            AppTextField(
              label: LocaleKeys.products_notes.tr(),
              hint: LocaleKeys.products_optional.tr(),
              controller: _notes,
              onChanged: notifier.updateNotes,
            ),
            if (currentState.canArchive) ...[
              const SizedBox(height: 32),
              SizedBox(
                height: ProductFormMetrics.buttonHeight,
                child: TextButton.icon(
                  key: const Key('product-archive-button'),
                  onPressed: _archive,
                  icon: Icon(Icons.inventory_2_outlined, color: colors.red5),
                  label: Text(
                    LocaleKeys.products_archiveProduct.tr(),
                    style: context.textStyles.sansBodyBold.copyWith(color: colors.red5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({this.url, this.isUploading = false});

  final String? url;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      key: const Key('product-photo-slot'),
      height: ProductFormMetrics.photoHeight,
      decoration: BoxDecoration(
        color: colors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.neutral3),
      ),
      alignment: Alignment.center,
      child: isUploading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_a_photo_outlined, color: colors.neutral5),
                const SizedBox(height: 6),
                Text(
                  LocaleKeys.products_addPhoto.tr(),
                  style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
                ),
              ],
            ),
    );
  }
}

/// The design's `div.tile` rows, shown under the category field while the
/// typed text is a partial match of something already used.
class _CategorySuggestions extends StatelessWidget {
  const _CategorySuggestions({required this.suggestions, required this.onPick});

  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.neutral0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.neutral3),
        ),
        child: Column(
          children: [
            for (final value in suggestions)
              InkWell(
                onTap: () => onPick(value),
                child: SizedBox(
                  height: 44.5,
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.sell_outlined, size: 20, color: colors.neutral6),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(value, style: context.textStyles.sansBody),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
