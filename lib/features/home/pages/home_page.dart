import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/home/states/home_state.dart';
import 'package:mine_storage/features/home/widgets/post_item.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';
import 'package:mine_storage/shared/ui/theme_mode_button.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

/// Reference screen for the architecture: Retrofit → model → repository →
/// entity → notifier → page, covering loading, error, empty and loaded.
class HomePage extends BasePage {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BasePageState<HomePage, HomeState, HomeStateNotifier> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // This screen renders loading inline, so the shared blocking overlay would
    // only dim an empty scaffold.
    allowToShowLoading = false;
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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

  @override
  void setCurrentState() => currentState = ref.watch(homeStateProvider);

  @override
  void setNotifier() => notifier = ref.read(homeStateProvider.notifier);

  @override
  void initDataFromConstructor() => notifier.loadInitial();

  @override
  Widget buildPageContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.home_title.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: LocaleKeys.home_signOut.tr(),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                ref.read(routerProvider).goNamed(AppRoutes.signInName);
              }
            },
          ),
          const ThemeModeButton(),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (currentState.isLoading && currentState.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentState.showFullScreenError) {
      return ErrorAwareContainer(
        message: currentState.errorMessage ?? currentState.errorMessageKey?.tr() ?? LocaleKeys.home_loadFailed.tr(),
        onRetry: notifier.loadInitial,
      );
    }

    if (currentState.isEmpty) {
      return EmptyView(
        title: LocaleKeys.home_emptyTitle.tr(),
        subtitle: LocaleKeys.home_emptySubtitle.tr(),
        actionLabel: LocaleKeys.home_reload.tr(),
        onAction: notifier.loadInitial,
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: currentState.posts.length + (currentState.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= currentState.posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            );
          }
          return PostItem(post: currentState.posts[index]);
        },
      ),
    );
  }
}
