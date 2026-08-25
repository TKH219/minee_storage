import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/settings/states/settings_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';

/// Where else this product is stocked.
///
/// The design draws nothing here — a product was a per-shop row when it was
/// drawn. It is the one cue that the same catalogue entry holds stock
/// elsewhere, so it expands rather than hides behind a navigation the store
/// switcher would need, which is out of scope.
class OtherStoresSection extends ConsumerStatefulWidget {
  const OtherStoresSection({super.key, required this.holdings});

  final List<StoreHolding> holdings;

  @override
  ConsumerState<OtherStoresSection> createState() => _OtherStoresSectionState();
}

class _OtherStoresSectionState extends ConsumerState<OtherStoresSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.holdings.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final money = ref.watch(currencyFormatterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.neutral0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.neutral3),
        ),
        child: Column(
          children: [
            InkWell(
              key: const Key('other-stores-header'),
              onTap: () => setState(() => _expanded = !_expanded),
              child: SizedBox(
                height: 44.5,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.storefront_outlined, size: 20, color: colors.neutral6),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        LocaleKeys.products_otherStores.tr(),
                        style: context.textStyles.sansBody,
                      ),
                    ),
                    Text(
                      '${widget.holdings.length}',
                      style: context.textStyles.monoBody.copyWith(color: colors.neutral6),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: colors.neutral4,
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
            if (_expanded)
              for (final holding in widget.holdings)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  child: SizedBox(
                    height: 44.5,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            holding.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.sansBody,
                          ),
                        ),
                        Text(
                          formatQuantity(holding.remaining),
                          style: context.textStyles.monoBody.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (holding.latestUnitPrice != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            money.format(holding.latestUnitPrice!),
                            style: context.textStyles.monoBody.copyWith(
                              color: colors.neutral6,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
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
