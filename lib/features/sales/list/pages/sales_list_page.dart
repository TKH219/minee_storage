import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/list/states/ledger_list_state.dart';
import 'package:mine_storage/features/sales/list/states/store_currency_state.dart';
import 'package:mine_storage/features/sales/list/widgets/ledger_labels.dart';
import 'package:mine_storage/features/sales/list/widgets/ledger_row.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_filter_chip.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';

/// S25 — the ledger. Four movement types in one list, grouped by day, with each
/// header carrying the net money that day moved.
class SalesListPage extends BasePage {
  const SalesListPage({super.key});

  @override
  ConsumerState<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState
    extends BasePageState<SalesListPage, LedgerListState, LedgerListStateNotifier> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    // The list renders its own skeleton rows, so the blocking overlay would
    // only dim an empty scaffold.
    allowToShowLoading = false;
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      notifier.loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => notifier.search(value));
  }

  @override
  void setCurrentState() => currentState = ref.watch(ledgerListStateProvider);

  @override
  void setNotifier() => notifier = ref.read(ledgerListStateProvider.notifier);

  @override
  void initDataFromConstructor() => notifier.loadInitial();

  @override
  Widget buildPageContent(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(title: Text(LocaleKeys.sales_title.tr())),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchRow(context),
            _buildTypeFilters(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        key: const Key('ledger-search-field'),
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: LocaleKeys.sales_ledgerSearchHint.tr(),
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      ),
    );
  }

  /// Type is the filter a shopkeeper reaches for first, so it sits on the
  /// screen rather than behind a sheet.
  Widget _buildTypeFilters(BuildContext context) {
    final selected = currentState.filter.type;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          AppFilterChip(
            key: const Key('ledger-filter-all'),
            label: LocaleKeys.sales_ledgerFilterAll.tr(),
            selected: selected == null,
            onTap: () => notifier.setType(null),
          ),
          for (final type in TransactionType.values) ...[
            const SizedBox(width: 8),
            AppFilterChip(
              key: Key('ledger-filter-${type.name}'),
              label: transactionTypeLabel(type),
              selected: selected == type,
              onTap: () => notifier.setType(selected == type ? null : type),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (currentState.isLoading && currentState.days.isEmpty) {
      return const _LedgerSkeleton();
    }

    if (currentState.showFullScreenError) {
      return ErrorAwareContainer(
        message: currentState.errorMessageKey?.tr() ??
            currentState.errorMessage ??
            LocaleKeys.errors_generic.tr(),
        onRetry: notifier.loadInitial,
      );
    }

    if (currentState.isEmpty) {
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        title: LocaleKeys.sales_ledgerEmptyTitle.tr(),
        subtitle: LocaleKeys.sales_ledgerEmptySubtitle.tr(),
      );
    }

    if (currentState.hasNoResults) {
      return EmptyView(
        key: const Key('ledger-no-results'),
        icon: Icons.filter_alt_off_outlined,
        title: LocaleKeys.sales_ledgerNoResultsTitle.tr(),
        subtitle: LocaleKeys.sales_ledgerNoResultsSubtitle.tr(),
        actionLabel: LocaleKeys.sales_ledgerClearFilters.tr(),
        onAction: () {
          _searchController.clear();
          notifier.clearFilters();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: _buildDayList(context),
    );
  }

  Widget _buildDayList(BuildContext context) {
    final formatter = ref.watch(storeCurrencyFormatterProvider);
    final today = ref.read(nowProvider)();

    // Flattened so one scroll view carries every day, and a day that spans two
    // pages keeps a single header rather than repeating it.
    final slivers = <Widget>[];
    for (final day in currentState.days) {
      slivers.add(
        LedgerDayHeader(day: day, formatter: formatter, today: today),
      );
      for (final transaction in day.transactions) {
        slivers.add(
          LedgerRow(
            key: Key('ledger-row-${transaction.id}'),
            transaction: transaction,
            formatter: formatter,
          ),
        );
      }
    }

    if (currentState.nextPageFailed) {
      slivers.add(_buildRetryRow(context));
    } else if (currentState.isLoadingMore) {
      slivers.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: ButtonDots()),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: slivers,
    );
  }

  /// The rows already fetched keep their place; the retry sits where the
  /// missing page would have been.
  Widget _buildRetryRow(BuildContext context) {
    return Padding(
      key: const Key('ledger-next-page-retry'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Text(
            LocaleKeys.sales_ledgerPageFailed.tr(),
            style: context.textStyles.sansCaption.copyWith(
              color: context.colors.neutral6,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: notifier.retryNextPage,
            child: Text(LocaleKeys.sales_ledgerRetryPage.tr()),
          ),
        ],
      ),
    );
  }
}

/// The same skeleton geometry the product list uses, plus a short bar for the
/// day header, so nothing reflows when the real rows arrive.
class _LedgerSkeleton extends StatelessWidget {
  const _LedgerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('ledger-skeleton'),
      padding: const EdgeInsets.only(top: 8),
      children: const [
        SkeletonRow(),
        SkeletonRow(),
        SkeletonRow(),
        SkeletonRow(),
        SkeletonRow(),
      ],
    );
  }
}
