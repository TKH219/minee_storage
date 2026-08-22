import 'package:mine_storage/data/data_sources/remote/user_api.dart';

/// The parts of auth that are table reads and writes rather than sessions.
///
/// Split out so [AuthDataSourceImpl] keeps only what GoTrue genuinely owns —
/// credentials, the OTP and the session — and everything else goes over REST.
class AuthTableDataSource {
  const AuthTableDataSource(this._api);

  final UserApi _api;

  Future<String> emailStatus(String email) => _api.emailStatus({'p_email': email});

  Future<Map<String, dynamic>?> fetchUserRow(String userId) async {
    final body = await _api.fetchUser(id: 'eq.$userId');
    if (body is! List || body.isEmpty) return null;
    return (body.first as Map).cast<String, dynamic>();
  }

  Future<void> touchLastSignedIn(String userId) {
    return _patch(userId, {'last_signed_in_at': _now()});
  }

  Future<void> updateProfileRow({
    required String userId,
    required String fullName,
    String? avatarUrl,
  }) {
    return _patch(userId, {
      'full_name': fullName,
      'avatar_url': ?avatarUrl,
    });
  }

  Future<void> stampOnboardingCompleted(String userId) {
    return _patch(userId, {'onboarding_completed_at': _now()});
  }

  Future<void> _patch(String userId, Map<String, dynamic> values) {
    return _api.updateUser('eq.$userId', {...values, 'updated_at': _now()});
  }

  String _now() => DateTime.now().toUtc().toIso8601String();
}
