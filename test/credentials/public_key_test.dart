import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

final pubKeys = {
  '038e5d1fccb6b800b4e0fde5080a8c3628a302c4767e7687bea79ba24c6ac268e2':
      '048e5d1fccb6b800b4e0fde5080a8c3628a302c4767e7687bea79ba24c6ac268e275392bb442ebba2b92e1bb00668d1c34f69c0e51aba49e3a0189f9674d80a8a1',
  '02c776abf37ebf543d1c28f1e44fb745128f51a7b897defb949de34e0735da1e29':
      '04c776abf37ebf543d1c28f1e44fb745128f51a7b897defb949de34e0735da1e29c757332d95941fca1cd0ed3e791f1234513d98fdfb24d2192ed5b61bf2391536',
  '02139b830244fe67ae534002a16f2ca227e6f8d1e9aafba8a83f9a58bf14aab619':
      '04139b830244fe67ae534002a16f2ca227e6f8d1e9aafba8a83f9a58bf14aab6195d7706766285ab1f71872e32f663e173eec70003c0172b798588b6b070223ac2',
  '02b3b865d9a86cf9521da22d135b0ee37d7acec35e83a14729c9c612110883db2a':
      '04b3b865d9a86cf9521da22d135b0ee37d7acec35e83a14729c9c612110883db2a9f67f78dc2c91b06c5cfd96ea568cb3907a424aa8c5ac99459140b3432357ffa',
  '02f76454105bf1bcc09d928930776f67c4ddc67dd3e19d66b93fa850fbfb2ec0c4':
      '04f76454105bf1bcc09d928930776f67c4ddc67dd3e19d66b93fa850fbfb2ec0c4d6ffc9b3c6f96809884b36c8ea3a0b5d7d7e8812a246c1b6f051d568df30986c',
  '0294409b98171941dfa953e22d508252ac9dce24211a6051cfc5288c7f2bd82419':
      '0494409b98171941dfa953e22d508252ac9dce24211a6051cfc5288c7f2bd82419543fe6afca1d98a5ac2b8c7c9c9223075e8d67ee971c6b57558dbefb763fa598',
  '0299208f9a219712054e93dd34ecf6cb7d3878e4df6f437164d3e7fb443b52a3ed':
      '0499208f9a219712054e93dd34ecf6cb7d3878e4df6f437164d3e7fb443b52a3ed07c3381510c8d48e1529b90bcf565ff7c8db221cafdad821549d8add4b188914',
  '02f29766aba359386368bec0e5f123f9c596b736f915e1963f58ede0b14b3cb99f':
      '04f29766aba359386368bec0e5f123f9c596b736f915e1963f58ede0b14b3cb99f746b6f6c50ca16d5b894cc6cb6b2323ab9978cf0de17754e619b693000266e66',
  '03d2046ccc091c5e62599e0f09fc6c410b56156e9202b0731bf8c4b6aa2a8db09e':
      '04d2046ccc091c5e62599e0f09fc6c410b56156e9202b0731bf8c4b6aa2a8db09ef9474b2a080a05d6a0fb7e200845a7cbb0b310ed08945835fd105fc94eeaf8c1',
  '03fd0bc424274448d2162329932094275da0746c34e776b530a11d3749eb209a02':
      '04fd0bc424274448d2162329932094275da0746c34e776b530a11d3749eb209a02aece16c649ece7d7054b81c332ea78549d3c78d6d949cbb42ec8ef953beaa6a5',
  '0311c757b9920c0cfa5165d3b8881cc26c15db92ef7d5f1a54d670189b14432f74':
      '0411c757b9920c0cfa5165d3b8881cc26c15db92ef7d5f1a54d670189b14432f7459cfbcf639d67437e9d51d1cf5d1a23715286ae0a31c5e21e2e69cc7906e7677',
  '03fede584566a6ad53e5d6c5b606b4e348a61dda8c7ca07b06f1095d8bdc28556c':
      '04fede584566a6ad53e5d6c5b606b4e348a61dda8c7ca07b06f1095d8bdc28556c8cedb3b168504bbf5fb408783183ddf062bf238422290c300ce92da06302b155',
  '03a5e614c13cf554740d9511d788edc7ebac939d6d10c2636a9ed2c05648c31bf8':
      '04a5e614c13cf554740d9511d788edc7ebac939d6d10c2636a9ed2c05648c31bf8d08c0fb9f672bac94125ce4dd9f748349118f7277540b31ac1532fcd8f8a6ac7',
  '03b2a1f693ba80940033c8950ac7b260506ce824317ab8300bc4235f4fb574de01':
      '04b2a1f693ba80940033c8950ac7b260506ce824317ab8300bc4235f4fb574de015d849bbc860ae2955f89ff50f54861ec1877eb07832c69f92b30124918fa5cb3',
  '0285a52a6c98faa9c460311b525f3e3206e2bb3da8bb4d7f6d9d0d26f156ab3899':
      '0485a52a6c98faa9c460311b525f3e3206e2bb3da8bb4d7f6d9d0d26f156ab3899dfd3e79ada5840387c8ba5407c8750b605f7ed121ad317f8e3694b9356c33996',
  '0317f33f63c22171fccb30ff14f73c32245b262b9d564e60367a80f64556a7dc70':
      '0417f33f63c22171fccb30ff14f73c32245b262b9d564e60367a80f64556a7dc708cfac410459d79c956ba9930b051080273da7fe4d1bc46bd5fe30a6c39087561',
  '03ae643be85eacad9956164aa4cef4b98118cb56848eb98fde2111c27d0c887d5a':
      '04ae643be85eacad9956164aa4cef4b98118cb56848eb98fde2111c27d0c887d5a88b5af6e90c7b37eb1984fe3602cf18b4013d107f5203562198c5796343de38f',
  '027ca219a794f0e45278d1f5ddaf1c637dc38e3a64744fff1058ed56e7e9674855':
      '047ca219a794f0e45278d1f5ddaf1c637dc38e3a64744fff1058ed56e7e9674855f992b9305101f28eeaa8f981f752b91c4570b1ef7c2ac8e5bbe86d151836c202',
  '03d62489b549324a78c61fe19e967296ea0e3b368244f5edb2b307bd19124b02c5':
      '04d62489b549324a78c61fe19e967296ea0e3b368244f5edb2b307bd19124b02c5bb5443fe589b9f0be9e0d91bb10b89ee214c066ad92ee71dccd1af3345913ca1',
  '036c5c3d1144c2809abdc64c93e674c0b060c792f0a3dda71589fa9f6743d6f816':
      '046c5c3d1144c2809abdc64c93e674c0b060c792f0a3dda71589fa9f6743d6f8162375ea09d9f3b8bf191c97c00bc3d2c67db279e838a282e3c5464d93a0933c4d',
};

void main() {
  test('decompresses secp256k1 public keys', () {
    pubKeys.forEach((compressed, uncompressed) {
      var bytes = hexToBytes(compressed);
      var pubKeyBytes = decompressPublicKey(bytes);
      expect(bytesToHex(pubKeyBytes), uncompressed);

      bytes = hexToBytes(uncompressed);
      pubKeyBytes = compressPublicKey(bytes);
      expect(bytesToHex(pubKeyBytes), compressed);
    });
  });
}
