import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/features/profile/data/user_profile_repository.dart';

void main() {
  test('displayNameFor returns profile name when present', () {
    const names = {'user-1': 'Sarah Chen'};

    expect(displayNameFor(names, 'user-1'), 'Sarah Chen');
  });

  test('displayNameFor falls back calmly when profile is missing', () {
    expect(displayNameFor(const {}, 'user-1'), 'Someone');
  });

  test('displayNameFor falls back calmly when profile name is blank', () {
    const names = {'user-1': '   '};

    expect(displayNameFor(names, 'user-1'), 'Someone');
  });
}
