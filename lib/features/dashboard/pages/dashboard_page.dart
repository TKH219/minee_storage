import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/dashboard/states/dashboard_state.dart';
import 'package:mine_storage/features/products/states/product_list_state.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/ui/loading_circle.dart';

import '../widgets/attention_notice.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_empty_view.dart';
import '../widgets/dashboard_metrics.dart';
import '../widgets/kpi_tile.dart';
import '../widgets/sparkline.dart';

/// S08 — the app's true home. It answers "how did today go?" before anything
/// else, and an empty shop gets an instruction rather than six zeroes.
class DashboardPage extends BasePage {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState
    extends BasePageState<DashboardPage, DashboardState, DashboardStateNotifier> {
  @override
  void initState() {
    // Loading renders inline; the shared overlay would only dim an empty
    // scaffold.
    allowToShowLoading = false;
    super.initState();
  }

  @override
  void setCurrentState() => currentState = ref.watch(dashboardStateProvider);

  @override
  void setNotifier() => notifier = ref.read(dashboardStateProvider.notifier);

  @override
  void initDataFromConstructor() => notifier.load();

  @override
  Widget buildPageContent(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: DashboardAppBar(
        storeName: currentState.storeName,
        onSwitchStore: _switchStore,
        onOpenSettings: () => context.goNamed(AppRoutes.settingsName),
      ),
      body: SafeArea(top: false, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (currentState.showFullScreenError) {
      return ErrorAwareContainer(
        message: currentState.errorMessage ??
            (currentState.errorMessageKey ?? LocaleKeys.errors_generic).tr(),
        onRetry: notifier.load,
      );
    }
    if (currentState.isInit || currentState.isLoading) {
      return const Center(child: LoadingCircle());
    }
    if (currentState.isEmpty) {
      return DashboardEmptyView(
        onAddProduct: () => context.pushNamed(AppRoutes.productNewName),
        onScanBarcode: () => context.pushNamed(AppRoutes.productScanName),
      );
    }
    return _buildLoaded(context);
  }

  Widget _buildLoaded(BuildContext context) {
    final summary = currentState.summary;
    if (summary == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: DashboardMetrics.todayPadding,
            child: Text(
              LocaleKeys.dashboard_today.tr(
                namedArgs: {'date': _todayFormat.format(currentState.today)},
              ),
              style: context.textStyles.sansCaption.copyWith(
                fontSize: DashboardMetrics.todaySize,
                color: context.colors.neutral6,
              ),
            ),
          ),
          _buildKpiGrid(context, summary),
          if (currentState.alerts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: DashboardMetrics.sectionPadding,
              child: Text(
                LocaleKeys.dashboard_needsAttention.tr().toUpperCase(),
                style: context.textStyles.sansCaption.copyWith(
                  fontSize: DashboardMetrics.sectionLabelSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: DashboardMetrics.sectionLabelSpacing,
                  color: context.colors.neutral6,
                ),
              ),
            ),
            const SizedBox(height: DashboardMetrics.sectionBottomGap),
            _buildAlerts(context),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, SalesDashboardSummary summary) {
    final money = CurrencyFormatter(currentState.currency);
    final colors = context.colors;
    final profitPositive = summary.netProfit >= Decimal.zero;

    Widget row(List<Widget> tiles) => Padding(
      padding: DashboardMetrics.kpiGridPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            if (index > 0) const SizedBox(width: DashboardMetrics.kpiGap),
            Expanded(child: tiles[index]),
          ],
        ],
      ),
    );

    return Column(
      children: [
        IntrinsicHeight(
          child: row([
            KpiTile(
              id: 'revenue',
              label: LocaleKeys.dashboard_kpiRevenue.tr(),
              value: money.format(summary.revenue),
              delta: summary.revenueDelta,
            ),
            KpiTile(
              id: 'netProfit',
              label: LocaleKeys.dashboard_kpiNetProfit.tr(),
              value: money.format(summary.netProfit),
              delta: summary.netProfitDelta,
              valueColor: profitPositive ? colors.green5 : colors.red5,
            ),
          ]),
        ),
        const SizedBox(height: DashboardMetrics.kpiGap),
        IntrinsicHeight(
          child: row([
            KpiTile(
              id: 'salesCount',
              label: LocaleKeys.dashboard_kpiSales.tr(),
              value: '${summary.salesCount}',
              delta: summary.salesCountDelta,
            ),
            KpiTile(
              id: 'avgBasket',
              label: LocaleKeys.dashboard_kpiAvgBasket.tr(),
              value: money.format(summary.avgBasket),
              delta: summary.avgBasketDelta,
            ),
          ]),
        ),
        const SizedBox(height: DashboardMetrics.kpiGap),
        Padding(
          padding: DashboardMetrics.kpiGridPadding,
          child: KpiTile(
            id: 'lastSevenDays',
            label: LocaleKeys.dashboard_kpiLastSevenDays.tr(),
            value: money.format(summary.lastSevenDaysRevenue),
            delta: null,
            child: Sparkline(series: summary.lastSevenDaysSeries),
          ),
        ),
      ],
    );
  }

  Widget _buildAlerts(BuildContext context) {
    final money = CurrencyFormatter(currentState.currency);

    return Padding(
      padding: DashboardMetrics.sectionPadding,
      child: Column(
        children: [
          for (final alert in currentState.alerts) ...[
            if (alert != currentState.alerts.first)
              const SizedBox(height: DashboardMetrics.noticeStackGap),
            AttentionNotice(
              kind: alert.kind,
              headline: _headlineFor(alert),
              body: _bodyFor(alert, money),
              onTap: () => _openAlert(alert),
            ),
          ],
        ],
      ),
    );
  }

  String _headlineFor(AttentionAlert alert) => switch (alert.kind) {
    AttentionAlertKind.expired => LocaleKeys.dashboard_alertExpired.tr(
      namedArgs: {'count': '${alert.count}'},
    ),
    AttentionAlertKind.expiringSoon => LocaleKeys.dashboard_alertExpiring.tr(
      namedArgs: {'count': '${alert.count}'},
    ),
    AttentionAlertKind.outOfStock => alert.count == 1
        ? LocaleKeys.dashboard_alertOutOfStockOne.tr(
            namedArgs: {'name': alert.productNames.single},
          )
        : LocaleKeys.dashboard_alertOutOfStockMany.tr(
            namedArgs: {'count': '${alert.count}'},
          ),
  };

  String _bodyFor(AttentionAlert alert, CurrencyFormatter money) => switch (alert.kind) {
    AttentionAlertKind.expired => LocaleKeys.dashboard_alertExpiredBody.tr(
      namedArgs: {'names': alert.productNames.join(', ')},
    ),
    AttentionAlertKind.expiringSoon => LocaleKeys.dashboard_alertExpiringBody.tr(
      namedArgs: {'value': money.format(alert.valueAtCost ?? Decimal.zero)},
    ),
    AttentionAlertKind.outOfStock => alert.count == 1
        ? LocaleKeys.dashboard_alertOutOfStockOneBody.tr()
        : LocaleKeys.dashboard_alertOutOfStockManyBody.tr(
            namedArgs: {'names': alert.productNames.join(', ')},
          ),
  };

  /// Every alert leads into the screen that fixes it, filtered to exactly the
  /// products it named.
  void _openAlert(AttentionAlert alert) {
    final quickFilter = switch (alert.kind) {
      AttentionAlertKind.expired => ProductQuickFilter.expired,
      AttentionAlertKind.expiringSoon => ProductQuickFilter.expiringSoon,
      AttentionAlertKind.outOfStock => ProductQuickFilter.all,
    };
    unawaited(ref.read(productListStateProvider.notifier).setQuickFilter(quickFilter));
    context.goNamed(AppRoutes.productsName);
  }

  void _switchStore() {}
}

/// Matches the rest of the app: patterns carry no locale, so a date reads the
/// same way on every screen.
final DateFormat _todayFormat = DateFormat('EEE d MMM');
