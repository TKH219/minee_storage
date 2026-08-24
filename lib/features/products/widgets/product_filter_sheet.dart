import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/extensions/date_time_extensions.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_filter_chip.dart';

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({
    super.key,
    required this.current,
    required this.categories,
  });

  final ProductFilter current;
  final List<String> categories;

  static Future<ProductFilter?> show(
    BuildContext context, {
    required ProductFilter current,
    required List<String> categories,
  }) {
    return showModalBottomSheet<ProductFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductFilterSheet(current: current, categories: categories),
    );
  }

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late ProductFilter _draft = widget.current;

  Future<void> _pickRange({required bool created}) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (range == null) return;
    setState(() {
      _draft = created
          ? _draft.copyWith(createdFrom: range.start, createdTo: range.end)
          : _draft.copyWith(expiryFrom: range.start, expiryTo: range.end);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.products_filtersTitle.tr(),
              style: context.textStyles.sansTitleHeading3,
            ),
            const SizedBox(height: 16),
            _RangeTile(
              label: LocaleKeys.products_addedBetween.tr(),
              value: _draft.createdFrom == null
                  ? LocaleKeys.products_anyDate.tr()
                  : '${_draft.createdFrom.formatOr('—')} → ${_draft.createdTo.formatOr('—')}',
              onTap: () => _pickRange(created: true),
              onClear: _draft.createdFrom == null
                  ? null
                  : () => setState(
                      () => _draft = _draft.copyWith(clearCreatedRange: true),
                    ),
            ),
            _RangeTile(
              label: LocaleKeys.products_expiresBetween.tr(),
              value: _draft.expiryFrom == null
                  ? LocaleKeys.products_anyDate.tr()
                  : '${_draft.expiryFrom.formatOr('—')} → ${_draft.expiryTo.formatOr('—')}',
              onTap: () => _pickRange(created: false),
              onClear: _draft.expiryFrom == null
                  ? null
                  : () => setState(
                      () => _draft = _draft.copyWith(clearExpiryRange: true),
                    ),
            ),
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                LocaleKeys.products_category.tr(),
                style: context.textStyles.sansBodyBold,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final category in widget.categories)
                    AppFilterChip(
                      label: category,
                      selected: _draft.category == category,
                      onTap: () => setState(() {
                        _draft = _draft.category == category
                            ? _draft.copyWith(clearCategory: true)
                            : _draft.copyWith(category: category);
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      ProductFilter(
                        query: _draft.query,
                        quickFilter: _draft.quickFilter,
                      ),
                    ),
                    child: Text(LocaleKeys.products_clearAll.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_draft),
                    child: Text(LocaleKeys.products_apply.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeTile extends StatelessWidget {
  const _RangeTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: context.textStyles.sansBodyBold),
      subtitle: Text(
        value,
        style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6),
      ),
      trailing: onClear == null
          ? const Icon(Icons.chevron_right_rounded)
          : IconButton(icon: const Icon(Icons.close_rounded), onPressed: onClear),
      onTap: onTap,
    );
  }
}
