import 'package:test/test.dart';
import 'package:web3x/crypto.dart';
import 'package:web3x/src/utils/extensions.dart';

void main() {
  test('strip 0x prefix', () {
    expect('0x12F312319235'.stripOx(), '12F312319235');
    expect('123123'.stripOx(), '123123');
  });

  test('hexToDartInt', () {
    expect(hexToDartInt('0x123'), 0x123);
    expect(hexToDartInt('0xff'), 0xff);
    expect(hexToDartInt('abcdef'), 0xabcdef);
  });

  test('bytesToHex', () {
    expect(bytesToHex([3], padToEvenLength: true), '03');
    expect(bytesToHex([3], forcePadLength: 3), '003');
  });
}
