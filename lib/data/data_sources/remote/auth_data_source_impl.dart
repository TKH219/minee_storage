import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/data/data_sources/remote/auth_data_source.dart';

class AuthDataSourceImpl implements AuthDataSource {
  AuthDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
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
