/// The `public.users` row and the email-existence RPC, over REST.
abstract class UserProfileDataSource {
  Future<String> emailStatus(String email);

  Future<Map<String, dynamic>?> fetchUserRow(String userId);

  Future<void> touchLastSignedIn(String userId);

  Future<void> updateProfileRow({
    required String userId,
    required String fullName,
    String? avatarUrl,
  });

  Future<void> stampOnboardingCompleted(String userId);
}
