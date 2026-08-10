abstract class AuthDataSource {
  Future<String> emailStatus(String email);

  Future<void> signUp({
    required String email,
    required String password,
    required String shopName,
  });

  Future<void> resendSignUpCode(String email);

  Future<String> verifySignUpCode({required String email, required String token});

  Future<String> signInWithPassword({required String email, required String password});

  Future<void> sendPasswordResetCode(String email);

  Future<void> verifyRecoveryCode({required String email, required String token});

  Future<void> updatePassword(String password);

  Future<void> signOut();

  Future<Map<String, dynamic>?> fetchUserRow(String userId);

  Future<void> touchLastSignedIn(String userId);

  Future<void> updateShopName({required String userId, required String shopName});

  String? get currentUserId;

  Stream<bool> get authStateChanges;
}
