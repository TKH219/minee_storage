import 'dart:async';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.emailStatus = EmailStatus.none, this.error});

  UserEntity? user;
  EmailStatus emailStatus;
  Object? error;

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
  Future<void> startSignUp({
    required String email,
    required String password,
    required String shopName,
  }) async {
    calls.add('startSignUp:$email:$shopName');
    _maybeThrow();
  }

  @override
  Future<void> resendSignUpCode(String email) async {
    calls.add('resendSignUpCode:$email');
    _maybeThrow();
  }

  @override
  Future<UserEntity> confirmSignUp({
    required String email,
    required String token,
    required String shopName,
    required bool wasResumed,
  }) async {
    calls.add('confirmSignUp:$token:resumed=$wasResumed');
    _maybeThrow();
    return user ?? UserEntity(id: 'uid-1', email: email, shopName: shopName);
  }

  @override
  Future<UserEntity> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    _maybeThrow();
    return user ?? UserEntity(id: 'uid-1', email: email, shopName: 'S');
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
  Future<UserEntity?> currentUser() async {
    calls.add('currentUser');
    return user;
  }

  @override
  Stream<bool> get authStateChanges => authStateController.stream;
}
