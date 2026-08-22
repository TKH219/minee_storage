/// Credentials, the one-time code, and the session — everything GoTrue owns.
///
/// Profile rows live next door in [UserProfileDataSource] and travel over REST;
/// the two are kept apart so neither has to know how the other talks.
abstract class AuthDataSource {
  Future<void> signUp({required String email, required String password});

  Future<void> resendSignUpCode(String email);

  Future<String> verifySignUpCode({required String email, required String token});

  Future<String> signInWithPassword({required String email, required String password});

  Future<void> sendPasswordResetCode(String email);

  Future<void> verifyRecoveryCode({required String email, required String token});

  Future<void> updatePassword(String password);

  Future<void> signOut();

  String? get currentUserId;

  Stream<bool> get authStateChanges;
}
