import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

const infuraProjectId = String.fromEnvironment('INFURA_ID');

void main() {
  group(
    'integration',
    () {
      late final Web3Client client;

      setUpAll(() {
        client = Web3Client(
          'https://mainnet.infura.io/v3/$infuraProjectId',
          Client(),
        );
      });

      // ignore: unnecessary_lambdas, https://github.com/dart-lang/linter/issues/2670
      tearDownAll(() => client.dispose());

      test('Web3Client.getBlockInformation', () async {
        final blockInfo = await client.getBlockInformation(
          blockNumber: const BlockNum.exact(14074702).toBlockParam(),
        );

        expect(
          blockInfo.timestamp.millisecondsSinceEpoch == 1643113026000,
          isTrue,
        );
        expect(
          blockInfo.timestamp.isUtc == true,
          isTrue,
        );
      });
    },
    skip: infuraProjectId.isEmpty
        ? 'Tests require the INFURA_ID environment variable'
        : null,
  );
}
