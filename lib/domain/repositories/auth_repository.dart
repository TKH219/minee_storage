import 'package:mine_storage/domain/entities/entities.dart';

/// Whether an address already has an account, and whether it was confirmed.
enum EmailStatus { none, unconfirmed, confirmed }

abstract class AuthRepository {
  Future<EmailStatus> checkEmail(String email);

  /// Creates the account and sends the 8-digit confirmation code.
  Future<void> startSignUp({required String email, required String password});

  /// Re-sends the confirmation code for an account that exists but was never
  /// confirmed. Needs no password, so a returning user is not asked for one.
  Future<void> resendSignUpCode(String email);

  /// Verifies the code and returns the profile row the trigger created.
  Future<UserEntity> confirmSignUp({required String email, required String token});

  Future<UserEntity> signIn({required String email, required String password});

  Future<void> startPasswordReset(String email);

  Future<void> verifyPasswordResetCode({required String email, required String token});

  Future<void> setNewPassword(String password);

  Future<void> signOut();

  Future<UserEntity> updateProfile({required String fullName, String? avatarUrl});

  /// Stamps `onboarding_completed_at`, which is what stops the gate from
  /// sending the user back through onboarding on the next launch.
  Future<void> completeOnboarding();

  Future<UserEntity?> currentUser();

  /// Emits true while a session exists. Drives the router redirect.
  Stream<bool> get authStateChanges;
}
