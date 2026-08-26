import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/dashboard/states/store_switcher_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/loading_circle.dart';

import 'store_switcher_metrics.dart';

Future<void> showStoreSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.neutral0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(StoreSwitcherMetrics.sheetRadius),
      ),
    ),
    builder: (_) => const StoreSwitcherSheet(),
  );
}

/// S07. Each store with its currency, what it holds, and the role held there.
///
/// The aggregate row is owner-only, and the notice is doing real work: nothing
/// here ever adds two currencies together.
class StoreSwitcherSheet extends ConsumerStatefulWidget {
  const StoreSwitcherSheet({super.key});

  @override
  ConsumerState<StoreSwitcherSheet> createState() => _StoreSwitcherSheetState();
}

class _StoreSwitcherSheetState extends ConsumerState<StoreSwitcherSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(storeSwitcherStateProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSwitcherStateProvider);
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: StoreSwitcherMetrics.sheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: StoreSwitcherMetrics.grabWidth,
                height: StoreSwitcherMetrics.grabHeight,
                margin: const EdgeInsets.only(
                  bottom: StoreSwitcherMetrics.grabBottomGap,
                ),
                decoration: BoxDecoration(
                  color: colors.neutral3,
                  borderRadius: BorderRadius.circular(
                    StoreSwitcherMetrics.grabHeight / 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: StoreSwitcherMetrics.blockGap),
            Padding(
              padding: StoreSwitcherMetrics.horizontalPadding,
              child: Text(
                LocaleKeys.stores_switchTitle.tr(),
                style: context.textStyles.sansBodyBold.copyWith(
                  fontSize: StoreSwitcherMetrics.titleSize,
                ),
              ),
            ),
            const SizedBox(height: StoreSwitcherMetrics.blockGap),
            if (state.isLoading || state.isInit)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingCircle(),
              )
            else
              ..._buildRows(context, state),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows(BuildContext context, StoreSwitcherState state) {
    final colors = context.colors;

    return [
      for (var index = 0; index < state.summaries.length; index++) ...[
        if (index > 0)
          Divider(height: 1, thickness: 1, color: colors.neutral2),
        _StoreTile(
          summary: state.summaries[index],
          selected:
              !state.allStores &&
              state.summaries[index].store.id == state.activeStoreId,
          onTap: () async {
            await ref
                .read(storeSwitcherStateProvider.notifier)
                .select(state.summaries[index].store.id);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
      if (state.canSeeAllStores) ...[
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(
            vertical: StoreSwitcherMetrics.dividerGap,
          ),
          color: colors.neutral2,
        ),
        _AllStoresTile(
          selected: state.allStores,
          onTap: () {
            ref.read(storeSwitcherStateProvider.notifier).selectAllStores();
            Navigator.of(context).pop();
          },
        ),
      ],
      if (state.mixedCurrencyCodes.isNotEmpty) ...[
        const SizedBox(height: StoreSwitcherMetrics.blockGap),
        Padding(
          padding: StoreSwitcherMetrics.horizontalPadding,
          child: _CurrencyNotice(codes: state.mixedCurrencyCodes),
        ),
      ],
    ];
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final StoreSummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: StoreSwitcherMetrics.tileMinHeight,
        ),
        child: Padding(
          padding: StoreSwitcherMetrics.tilePadding,
          child: Row(
            children: [
              _Radio(id: summary.store.id, selected: selected),
              const SizedBox(width: StoreSwitcherMetrics.tileGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      summary.store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.sansBody.copyWith(
                        fontSize: StoreSwitcherMetrics.labelSize,
                      ),
                    ),
                    Text(
                      LocaleKeys.stores_productCount.tr(
                        namedArgs: {
                          'code': summary.currency.code,
                          'count': '${summary.productCount}',
                        },
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.sansCaption.copyWith(
                        color: colors.neutral6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: StoreSwitcherMetrics.tileGap),
              _RoleBadge(role: summary.role),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllStoresTile extends StatelessWidget {
  const _AllStoresTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: StoreSwitcherMetrics.tileMinHeight,
        ),
        child: Padding(
          padding: StoreSwitcherMetrics.tilePadding,
          child: Row(
            children: [
              _Radio(id: 'all', selected: selected),
              const SizedBox(width: StoreSwitcherMetrics.tileGap),
              Expanded(
                child: Text(
                  LocaleKeys.stores_allStores.tr(),
                  style: context.textStyles.sansBody.copyWith(
                    fontSize: StoreSwitcherMetrics.labelSize,
                  ),
                ),
              ),
              Text(
                LocaleKeys.stores_aggregate.tr(),
                style: context.textStyles.monoBody.copyWith(
                  fontSize: StoreSwitcherMetrics.valueSize,
                  color: context.colors.neutral6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.id, required this.selected});

  final String id;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      key: Key('store-radio-$id'),
      width: StoreSwitcherMetrics.radioSize,
      height: StoreSwitcherMetrics.radioSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.primary4 : colors.neutral4,
          width: selected
              ? StoreSwitcherMetrics.radioSelectedBorder
              : StoreSwitcherMetrics.radioBorder,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final StoreRole role;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: StoreSwitcherMetrics.badgeHeight,
      padding: StoreSwitcherMetrics.badgePadding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.neutral2,
        borderRadius: BorderRadius.circular(StoreSwitcherMetrics.badgeRadius),
      ),
      child: Text(
        switch (role) {
          StoreRole.owner => LocaleKeys.stores_roleOwner.tr(),
          StoreRole.manager => LocaleKeys.stores_roleManager.tr(),
          StoreRole.staff => LocaleKeys.stores_roleStaff.tr(),
        },
        style: context.textStyles.sansCaption.copyWith(
          fontSize: StoreSwitcherMetrics.badgeTextSize,
          fontWeight: FontWeight.w600,
          color: colors.neutral6,
        ),
      ),
    );
  }
}

class _CurrencyNotice extends StatelessWidget {
  const _CurrencyNotice({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: StoreSwitcherMetrics.noticePadding,
      decoration: BoxDecoration(
        color: colors.orange0,
        borderRadius: BorderRadius.circular(StoreSwitcherMetrics.noticeRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: StoreSwitcherMetrics.noticeIconSize,
            color: colors.orange6,
          ),
          const SizedBox(width: StoreSwitcherMetrics.noticeGap),
          Expanded(
            child: Text(
              LocaleKeys.stores_mixedCurrency.tr(
                namedArgs: {'codes': codes.join(', ')},
              ),
              style: context.textStyles.sansBody.copyWith(
                fontSize: StoreSwitcherMetrics.noticeTextSize,
                height: StoreSwitcherMetrics.noticeTextHeight,
                color: colors.orange6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
