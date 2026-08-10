import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';

final homeStateProvider = AutoDisposeNotifierProvider<HomeStateNotifier, HomeState>(
  HomeStateNotifier.new,
);

class HomeState extends BaseState with Equatable {
  const HomeState({super.status, super.errorMessage});

  @override
  HomeState copyWith({StateLifeCycle? status, String? errorMessage}) {
    return HomeState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

class HomeStateNotifier extends BaseStateNotifier<HomeState> {
  @override
  HomeState createInitialState() => const HomeState();
}
