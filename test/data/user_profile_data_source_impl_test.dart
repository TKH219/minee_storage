import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/data_sources/remote/user_profile_data_source_impl.dart';

import '../support/fake_user_api.dart';
import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  test('a profile read filters by id in PostgREST grammar', () async {
    final api = FakeUserApi(userRows: [
      {'id': 'uid-1', 'email': 'a@b.com', 'full_name': 'Maya'},
    ]);

    final row = await UserProfileDataSourceImpl(api).fetchUserRow('uid-1');

    expect(api.lastQuery['id'], 'eq.uid-1');
    expect(row!['full_name'], 'Maya');
  });

  test('a missing profile row is null, not an error', () async {
    final row = await UserProfileDataSourceImpl(FakeUserApi()).fetchUserRow('uid-1');

    expect(row, isNull);
  });

  test('a profile write patches only the columns it was given', () async {
    final api = FakeUserApi();

    await UserProfileDataSourceImpl(api).updateProfileRow(userId: 'uid-1', fullName: 'Maya');

    expect(api.lastQuery['id'], 'eq.uid-1');
    expect(api.lastPatch['full_name'], 'Maya');
    expect(api.lastPatch.containsKey('avatar_url'), isFalse);
    expect(api.lastPatch['updated_at'], isNotNull);
  });

  test('an avatar url is included when there is one', () async {
    final api = FakeUserApi();

    await UserProfileDataSourceImpl(api)
        .updateProfileRow(userId: 'uid-1', fullName: 'Maya', avatarUrl: 'https://cdn/x.jpg');

    expect(api.lastPatch['avatar_url'], 'https://cdn/x.jpg');
  });

  test('stamping onboarding writes the completion timestamp', () async {
    final api = FakeUserApi();

    await UserProfileDataSourceImpl(api).stampOnboardingCompleted('uid-1');

    expect(api.lastPatch['onboarding_completed_at'], isNotNull);
  });

  test('the email-status rpc posts the address as its parameter', () async {
    final api = FakeUserApi(status: 'confirmed');

    final status = await UserProfileDataSourceImpl(api).emailStatus('a@b.com');

    expect(api.lastRpcBody, {'p_email': 'a@b.com'});
    expect(status, 'confirmed');
  });
}
