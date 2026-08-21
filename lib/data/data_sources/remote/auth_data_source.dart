abstract class AuthDataSource {
  Future<String> emailStatus(String email);

  Future<void> signUp({required String email, required String password});

  Future<void> resendSignUpCode(String email);

  Future<String> verifySignUpCode({required String email, required String token});

  Future<String> signInWithPassword({required String email, required String password});

  Future<void> sendPasswordResetCode(String email);

  Future<void> verifyRecoveryCode({required String email, required String token});

  Future<void> updatePassword(String password);

  Future<void> signOut();

  Future<Map<String, dynamic>?> fetchUserRow(String userId);

  Future<void> touchLastSignedIn(String userId);

  Future<void> updateProfileRow({
    required String userId,
    required String fullName,
    String? avatarUrl,
  });

  Future<void> stampOnboardingCompleted(String userId);

  String? get currentUserId;

  Stream<bool> get authStateChanges;
}
