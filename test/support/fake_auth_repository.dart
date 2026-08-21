import 'dart:async';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.user,
    this.emailStatus = EmailStatus.none,
    this.error,
    this.delay = Duration.zero,
  });

  UserEntity? user;
  EmailStatus emailStatus;
  Object? error;

  /// Held so widget tests can observe an in-flight state.
  Duration delay;

  String? lastAvatarUrl;

  final List<String> calls = [];
  final StreamController<bool> authStateController = StreamController<bool>.broadcast();

  void _maybeThrow() {
    if (error != null) throw error!;
  }

  @override
  Future<EmailStatus> checkEmail(String email) async {
    calls.add('checkEmail:$email');
    _maybeThrow();
    return emailStatus;
  }

  @override
  Future<void> startSignUp({required String email, required String password}) async {
    calls.add('startSignUp:$email');
    _maybeThrow();
  }

  @override
  Future<void> resendSignUpCode(String email) async {
    calls.add('resendSignUpCode:$email');
    _maybeThrow();
  }

  @override
  Future<UserEntity> confirmSignUp({required String email, required String token}) async {
    calls.add('confirmSignUp:$token');
    _maybeThrow();
    return user ?? UserEntity(id: 'uid-1', email: email);
  }

  @override
  Future<UserEntity> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    _maybeThrow();
    return user ?? UserEntity(id: 'uid-1', email: email, fullName: 'S');
  }

  @override
  Future<void> startPasswordReset(String email) async {
    calls.add('startPasswordReset:$email');
    _maybeThrow();
  }

  @override
  Future<void> verifyPasswordResetCode({
    required String email,
    required String token,
  }) async {
    calls.add('verifyPasswordResetCode:$token');
    _maybeThrow();
  }

  @override
  Future<void> setNewPassword(String password) async {
    calls.add('setNewPassword');
    _maybeThrow();
  }

  @override
  Future<void> signOut() async => calls.add('signOut');

  @override
  Future<UserEntity> updateProfile({required String fullName, String? avatarUrl}) async {
    calls.add('updateProfile:$fullName');
    lastAvatarUrl = avatarUrl;
    _maybeThrow();
    final updated = UserEntity(
      id: user?.id ?? 'uid-1',
      email: user?.email ?? 'a@b.com',
      fullName: fullName,
      avatarUrl: avatarUrl,
      onboardingCompletedAt: user?.onboardingCompletedAt,
    );
    user = updated;
    return updated;
  }

  @override
  Future<void> completeOnboarding() async {
    calls.add('completeOnboarding');
    _maybeThrow();
  }

  @override
  Future<UserEntity?> currentUser() async {
    calls.add('currentUser');
    return user;
  }

  @override
  Stream<bool> get authStateChanges => authStateController.stream;
}
