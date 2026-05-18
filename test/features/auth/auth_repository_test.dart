import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/features/auth/data/auth_repository.dart';

void main() {
  test('registration display name falls back to email name when blank', () {
    expect(
      registrationDisplayName(email: 'sarah@example.com', displayName: '  '),
      'sarah',
    );
  });

  test('registration display name trims provided name', () {
    expect(
      registrationDisplayName(
        email: 'sarah@example.com',
        displayName: '  Sarah Chen  ',
      ),
      'Sarah Chen',
    );
  });
}
