import 'package:supabase_flutter/supabase_flutter.dart';

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

class AuthDataSourceImpl implements AuthDataSource {
  AuthDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<String> emailStatus(String email) async {
    final result = await _client.rpc<dynamic>(
      'email_status',
      params: {'p_email': email},
    );
    return result as String;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String shopName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'shop_name': shopName},
    );
  }

  @override
  Future<void> resendSignUpCode(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  @override
  Future<String> verifySignUpCode({required String email, required String token}) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
    return _requireUserId(response);
  }

  @override
  Future<String> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _requireUserId(response);
  }

  @override
  Future<void> sendPasswordResetCode(String email) =>
      _client.auth.resetPasswordForEmail(email);

  @override
  Future<void> verifyRecoveryCode({required String email, required String token}) async {
    await _client.auth.verifyOTP(email: email, token: token, type: OtpType.recovery);
  }

  @override
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<Map<String, dynamic>?> fetchUserRow(String userId) {
    return _client.from('users').select().eq('id', userId).maybeSingle();
  }

  @override
  Future<void> touchLastSignedIn(String userId) async {
    await _client
        .from('users')
        .update({'last_signed_in_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', userId);
  }

  @override
  Future<void> updateShopName({required String userId, required String shopName}) async {
    await _client
        .from('users')
        .update({
          'shop_name': shopName,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<bool> get authStateChanges =>
      _client.auth.onAuthStateChange.map((state) => state.session != null);

  String _requireUserId(AuthResponse response) {
    final id = response.user?.id;
    if (id == null) {
      throw const AuthException('Authentication returned no user.');
    }
    return id;
  }
}
