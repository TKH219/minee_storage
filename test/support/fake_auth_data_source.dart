import 'package:mine_storage/data/data_sources/remote/auth_data_source.dart';

class FakeAuthDataSource implements AuthDataSource {
  FakeAuthDataSource({
    this.status = 'none',
    this.userId = 'uid-1',
    this.row,
    this.signInError,
    this.verifyError,
    this.touchError,
  });

  String status;
  String userId;
  Map<String, dynamic>? row;
  Object? signInError;
  Object? verifyError;
  Object? touchError;

  final List<String> calls = [];
  String? lastShopName;
  String? lastPassword;

  @override
  Future<String> emailStatus(String email) async {
    calls.add('emailStatus:$email');
    return status;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String shopName,
  }) async {
    calls.add('signUp:$email');
    lastShopName = shopName;
  }

  @override
  Future<void> resendSignUpCode(String email) async => calls.add('resend:$email');

  @override
  Future<String> verifySignUpCode({required String email, required String token}) async {
    calls.add('verifySignUp:$token');
    if (verifyError != null) throw verifyError!;
    return userId;
  }

  @override
  Future<String> signInWithPassword({
    required String email,
    required String password,
  }) async {
    calls.add('signIn:$email');
    if (signInError != null) throw signInError!;
    return userId;
  }

  @override
  Future<void> sendPasswordResetCode(String email) async => calls.add('reset:$email');

  @override
  Future<void> verifyRecoveryCode({required String email, required String token}) async {
    calls.add('verifyRecovery:$token');
    if (verifyError != null) throw verifyError!;
  }

  @override
  Future<void> updatePassword(String password) async {
    calls.add('updatePassword');
    lastPassword = password;
  }

  @override
  Future<void> signOut() async => calls.add('signOut');

  @override
  Future<Map<String, dynamic>?> fetchUserRow(String id) async {
    calls.add('fetchRow:$id');
    return row;
  }

  @override
  Future<void> touchLastSignedIn(String id) async {
    calls.add('touch:$id');
    if (touchError != null) throw touchError!;
  }

  @override
  Future<void> updateShopName({required String userId, required String shopName}) async {
    calls.add('updateShopName:$shopName');
    lastShopName = shopName;
  }

  @override
  String? get currentUserId => userId;

  @override
  Stream<bool> get authStateChanges => const Stream<bool>.empty();
}
