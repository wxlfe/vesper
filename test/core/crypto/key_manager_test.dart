import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/crypto/key_manager.dart';

void main() {
  test('ensures stable user content key for private routines', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final manager = KeyManager();

    final first = await manager.ensureUserContentKey('user-1');
    final second = await manager.ensureUserContentKey('user-1');

    expect(first, hasLength(32));
    expect(second, first);
  });
}
