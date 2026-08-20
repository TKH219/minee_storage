import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/core/base/base_state.dart';

import '../../support/auth_test_harness.dart';

class _ProbeState extends BaseState {
  const _ProbeState({super.status, super.errorMessageKey, super.errorMessage});

  @override
  _ProbeState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
  }) {
    return _ProbeState(
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class _ProbeNotifier extends BaseStateNotifier<_ProbeState> {
  @override
  _ProbeState createInitialState() => const _ProbeState();
}

/// The control. Deliberately not a [BaseStateNotifier]: on Riverpod 2 the
/// auto-dispose and keep-alive hierarchies are distinct types, so the two
/// probes cannot share a base class until 3.x unifies them.
class _KeepAliveProbeNotifier extends Notifier<_ProbeState> {
  @override
  _ProbeState build() => const _ProbeState();
}

final _autoDisposeProbeProvider = NotifierProvider<_ProbeNotifier, _ProbeState>(
  _ProbeNotifier.new,
  isAutoDispose: true,
);

final _keepAliveProbeProvider = NotifierProvider<_KeepAliveProbeNotifier, _ProbeState>(
  _KeepAliveProbeNotifier.new,
);

void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [routerProvider.overrideWithValue(buildTestRouter())],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a BaseStateNotifier provider is disposed once its last listener goes', () async {
    final container = buildContainer();

    final sub = container.listen(_autoDisposeProbeProvider.notifier, (_, _) {});
    final before = sub.read();
    sub.close();

    await Future<void>.delayed(Duration.zero);

    final after = container.read(_autoDisposeProbeProvider.notifier);
    expect(
      identical(before, after),
      isFalse,
      reason: 'auto-dispose must rebuild the notifier after the last listener is removed',
    );
  });

  test('a keep-alive provider retains its notifier across listeners', () async {
    final container = buildContainer();

    final sub = container.listen(_keepAliveProbeProvider.notifier, (_, _) {});
    final before = sub.read();
    sub.close();

    await Future<void>.delayed(Duration.zero);

    final after = container.read(_keepAliveProbeProvider.notifier);
    expect(identical(before, after), isTrue);
  });
}
