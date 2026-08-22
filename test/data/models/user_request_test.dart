import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/models/models.dart';

void main() {
  final at = DateTime.utc(2026, 8, 2, 9);

  test('a profile write carries only the name and the touch', () {
    final request = UpdateUserRequest(fullName: 'Maya Chen', updatedAt: at);

    expect(request.toJson(), {
      'full_name': 'Maya Chen',
      'updated_at': at.toIso8601String(),
    });
  });

  test('an avatar is included only when there is one', () {
    final request = UpdateUserRequest(
      fullName: 'Maya',
      avatarUrl: 'https://cdn/x.jpg',
      updatedAt: at,
    );

    expect(request.toJson()['avatar_url'], 'https://cdn/x.jpg');
  });

  test('stamping onboarding touches only that column', () {
    final request = UpdateUserRequest(onboardingCompletedAt: at, updatedAt: at);

    expect(request.toJson(), {
      'onboarding_completed_at': at.toIso8601String(),
      'updated_at': at.toIso8601String(),
    });
  });

  test('stamping the sign-in touches only that column', () {
    final request = UpdateUserRequest(lastSignedInAt: at, updatedAt: at);

    expect(request.toJson(), {
      'last_signed_in_at': at.toIso8601String(),
      'updated_at': at.toIso8601String(),
    });
  });

  test('the email-status rpc names its parameter, not a column', () {
    expect(const EmailStatusRequest(email: 'a@b.com').toJson(), {'p_email': 'a@b.com'});
  });
}
