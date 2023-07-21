import 'package:test/test.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/src/credentials/did.dart';

void main() {
  group('Generate ethr DID', () {
    test('from Ethereum Address', () {
      var address =
          EthereumAddress.fromHex('0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb');
      var ethrDID =
          EthrDID.fromEthereumAddress(address: address, chainNameOrId: '0x1');
      expect(
        ethrDID.did,
        'did:ethr:0x1:0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb',
      );
    });

    test('from PublicKey Encoded', () {
      final key = EthPrivateKey(
        hexToBytes(
          'a392604efc2fad9c0b3da43b5f698a2e3f270f170d859912be0d54742275c5f6',
        ),
      );
      var ethrDID =
          EthrDID.fromPublicKeyEncoded(credentials: key, chainNameOrId: '0x1');
      expect(
        bytesToHex(key.publicKey.getEncoded(), include0x: true),
        '0x02506bc1dc099358e5137292f4efdd57e400f29ba5132aa5d12b18dac1c1f6aaba',
      );
      expect(
        ethrDID.did,
        'did:ethr:0x1:0x02506bc1dc099358e5137292f4efdd57e400f29ba5132aa5d12b18dac1c1f6aaba',
      );
    });

    test('from Identifier', () {
      var ethrDID = EthrDID.fromIdentifier(
        identifier: 'web3dart',
        chainNameOrId: 'goerli',
      );
      expect(
        ethrDID.did,
        'did:ethr:goerli:web3dart',
      );
    });
  });
}
