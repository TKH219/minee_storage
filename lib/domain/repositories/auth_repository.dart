import 'package:mine_storage/domain/entities/entities.dart';

/// Whether an address already has an account, and whether it was confirmed.
enum EmailStatus { none, unconfirmed, confirmed }

abstract class AuthRepository {
  Future<EmailStatus> checkEmail(String email);

  /// Creates the account and sends the 8-digit confirmation code.
  Future<void> startSignUp({
    required String email,
    required String password,
    required String shopName,
  });

  /// Re-sends the confirmation code for an account that exists but was never
  /// confirmed. Needs no password, so a returning user is not asked for one.
  Future<void> resendSignUpCode(String email);

  /// Verifies the code. When [wasResumed], the trigger already wrote the row
  /// from the *first* attempt's metadata, so [shopName] is written over it.
  Future<UserEntity> confirmSignUp({
    required String email,
    required String token,
    required String shopName,
    required bool wasResumed,
  });

  Future<UserEntity> signIn({required String email, required String password});

  Future<void> startPasswordReset(String email);

  Future<void> verifyPasswordResetCode({required String email, required String token});

  Future<void> setNewPassword(String password);

  Future<void> signOut();

  Future<UserEntity?> currentUser();

  /// Emits true while a session exists. Drives the router redirect.
  Stream<bool> get authStateChanges;
}
