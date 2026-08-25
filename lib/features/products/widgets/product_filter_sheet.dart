import 'package:easy_localization/easy_localization.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/date_time_extensions.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/app_filter_chip.dart';

class ProductFilterSheet extends ConsumerStatefulWidget {
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
  ConsumerState<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends ConsumerState<ProductFilterSheet> {
  Timer? _countDebounce;
  int? _matchCount;
  bool _counting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recount());
  }

  @override
  void dispose() {
    _countDebounce?.cancel();
    super.dispose();
  }

  /// The apply button says what applying would do, so the sheet is not a guess
  /// followed by an empty list. Debounced because every tap re-queries.
  void _recount() {
    _countDebounce?.cancel();
    _countDebounce = Timer(const Duration(milliseconds: 250), () async {
      final storeId = ref.read(activeStoreProvider);
      if (storeId == null) return;
      if (mounted) setState(() => _counting = true);
      try {
        final page = await ref.read(productRepositoryProvider).getProducts(
          storeId: storeId,
          filter: _draft,
          page: 1,
          limit: 200,
        );
        if (mounted) setState(() { _matchCount = page.items.length; _counting = false; });
      } on Object {
        if (mounted) setState(() { _matchCount = null; _counting = false; });
      }
    });
  }

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
    _recount();
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
                  : () {
                      setState(
                        () => _draft = _draft.copyWith(clearCreatedRange: true),
                      );
                      _recount();
                    },
            ),
            _RangeTile(
              label: LocaleKeys.products_expiresBetween.tr(),
              value: _draft.expiryFrom == null
                  ? LocaleKeys.products_anyDate.tr()
                  : '${_draft.expiryFrom.formatOr('—')} → ${_draft.expiryTo.formatOr('—')}',
              onTap: () => _pickRange(created: false),
              onClear: _draft.expiryFrom == null
                  ? null
                  : () {
                      setState(
                        () => _draft = _draft.copyWith(clearExpiryRange: true),
                      );
                      _recount();
                    },
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
                      onTap: () {
                        setState(() {
                          _draft = _draft.category == category
                              ? _draft.copyWith(clearCategory: true)
                              : _draft.copyWith(category: category);
                        });
                        _recount();
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const Key('filter-clear-button'),
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
                    key: const Key('filter-apply-button'),
                    onPressed: _matchCount == 0
                        ? null
                        : () => Navigator.of(context).pop(_draft),
                    child: Text(
                      switch ((_counting, _matchCount)) {
                        (true, _) => LocaleKeys.products_apply.tr(),
                        (_, null) => LocaleKeys.products_apply.tr(),
                        (_, 0) => LocaleKeys.products_applyNone.tr(),
                        (_, final n) => LocaleKeys.products_applyCount.tr(
                          namedArgs: {'count': '$n'},
                        ),
                      },
                    ),
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
