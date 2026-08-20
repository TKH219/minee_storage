import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/post_repository.dart';
import 'package:mine_storage/providers.dart';

final homeStateProvider = NotifierProvider<HomeStateNotifier, HomeState>(
  HomeStateNotifier.new,
  isAutoDispose: true,
);

/// Reference state for a paged list screen. Copy this shape for new features.
class HomeState extends BaseState with Equatable {
  const HomeState({
    this.posts = const [],
    this.page = 1,
    this.hasReachedEnd = false,
    this.isLoadingMore = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final List<PostEntity> posts;
  final int page;
  final bool hasReachedEnd;
  final bool isLoadingMore;

  bool get isEmpty => isLoaded && posts.isEmpty;

  /// The full-screen error surface is only right when there is nothing to show;
  /// a failed *page* load keeps the list and surfaces a snack bar instead.
  bool get showFullScreenError => isError && posts.isEmpty;

  @override
  HomeState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    List<PostEntity>? posts,
    int? page,
    bool? hasReachedEnd,
    bool? isLoadingMore,
  }) {
    return HomeState(
      posts: posts ?? this.posts,
      page: page ?? this.page,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    posts,
    page,
    hasReachedEnd,
    isLoadingMore,
    status,
    errorMessageKey, errorMessage,
  ];
}

class HomeStateNotifier extends BaseStateNotifier<HomeState> {
  late final PostRepository _postRepository;

  @override
  HomeState createInitialState() {
    _postRepository = ref.read(postRepositoryProvider);
    return const HomeState();
  }

  Future<void> loadInitial() async {
    try {
      showLoading();
      final posts = await _postRepository.getPosts(page: 1, limit: Constants.defaultPageSize);
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          posts: posts,
          page: 1,
          hasReachedEnd: posts.length < Constants.defaultPageSize,
        ),
      );
    } on Object catch (e) {
      onError(e);
    }
  }

  /// Pull-to-refresh keeps the existing list on screen, so it must not flip the
  /// state to loading — that would swap the list for the blocking overlay.
  Future<void> refresh() async {
    try {
      final posts = await _postRepository.getPosts(page: 1, limit: Constants.defaultPageSize);
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          posts: posts,
          page: 1,
          hasReachedEnd: posts.length < Constants.defaultPageSize,
        ),
      );
    } on Object catch (e) {
      onError(e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd || state.posts.isEmpty) return;

    final nextPage = state.page + 1;
    updateState(state.copyWith(isLoadingMore: true));
    try {
      final posts = await _postRepository.getPosts(
        page: nextPage,
        limit: Constants.defaultPageSize,
      );
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          posts: [...state.posts, ...posts],
          page: nextPage,
          hasReachedEnd: posts.length < Constants.defaultPageSize,
          isLoadingMore: false,
        ),
      );
    } on Object catch (e) {
      updateState(state.copyWith(isLoadingMore: false));
      onError(e);
    }
  }
}
