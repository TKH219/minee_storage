import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/dashboard/states/dashboard_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/ui/loading_circle.dart';

import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_empty_view.dart';
import '../widgets/dashboard_metrics.dart';

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
        ],
      ),
    );
  }


  void _switchStore() {}
}

/// Matches the rest of the app: patterns carry no locale, so a date reads the
/// same way on every screen.
final DateFormat _todayFormat = DateFormat('EEE d MMM');
