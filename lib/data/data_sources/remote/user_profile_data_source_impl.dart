import 'package:mine_storage/data/data_sources/remote/user_api.dart';
import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/data/data_sources/remote/user_profile_data_source.dart';

class UserProfileDataSourceImpl implements UserProfileDataSource {
  const UserProfileDataSourceImpl(this._api);

  final UserApi _api;

  @override
  Future<String> emailStatus(String email) =>
      _api.emailStatus(EmailStatusRequest(email: email));

  @override
  Future<UserModel?> fetchUserRow(String userId) async {
    final rows = await _api.fetchUser(id: 'eq.$userId');
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> touchLastSignedIn(String userId) {
    return _patch(userId, (now) => UpdateUserRequest(lastSignedInAt: now, updatedAt: now));
  }

  @override
  Future<void> updateProfileRow({
    required String userId,
    required String fullName,
    String? avatarUrl,
  }) {
    return _patch(
      userId,
      (now) => UpdateUserRequest(
        fullName: fullName,
        avatarUrl: avatarUrl,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> stampOnboardingCompleted(String userId) {
    return _patch(
      userId,
      (now) => UpdateUserRequest(onboardingCompletedAt: now, updatedAt: now),
    );
  }

  Future<void> _patch(String userId, UpdateUserRequest Function(DateTime now) build) {
    return _api.updateUser('eq.$userId', build(DateTime.now().toUtc()));
  }
}
