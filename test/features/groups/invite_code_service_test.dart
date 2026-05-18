import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/features/groups/domain/invite_code_service.dart';

void main() {
  test('generates human-enterable invite codes with Vesper prefix', () {
    final service = InviteCodeService(randomBytes: (_) => [1, 35, 69, 103]);

    final code = service.generateCode();

    expect(code, startsWith('VESPER-'));
    expect(code.length, lessThanOrEqualTo(14));
    expect(service.isValidCode(code), isTrue);
  });

  test('hashes invite codes case-insensitively', () {
    final service = InviteCodeService();

    expect(
      service.hashCodeForLookup('vesper-7k4m9q'),
      service.hashCodeForLookup('VESPER-7K4M9Q'),
    );
  });
}
