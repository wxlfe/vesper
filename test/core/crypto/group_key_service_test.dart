import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/crypto/group_key_service.dart';

void main() {
  test(
    'wraps group key for a member public key and unwraps with private key',
    () async {
      final service = GroupKeyService();
      final memberKeyPair = await service.newMemberKeyPair();
      final groupKey = service.newGroupKeyBytes();

      final wrapped = await service.wrapGroupKey(
        groupKey: groupKey,
        memberPublicKey: memberKeyPair.publicKey,
      );

      expect(wrapped.encryptedGroupKey, isNotEmpty);
      expect(wrapped.encryptedGroupKey, isNot(String.fromCharCodes(groupKey)));

      final unwrapped = await service.unwrapGroupKey(
        wrappedKey: wrapped,
        memberKeyPair: memberKeyPair,
      );

      expect(unwrapped, groupKey);
    },
  );
}
