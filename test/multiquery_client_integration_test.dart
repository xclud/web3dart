import 'dart:convert';

import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

const infuraProjectId = String.fromEnvironment('INFURA_ID');

void main() {
  final contract = DeployedContract(
    ContractAbi.fromJson(erc20TestTokenAbi, 'Link ERC20'),
    EthereumAddress.fromHex(
      '0x326C977E6efc84E512bB9C30f76E30c160eD06FB',
    ),
  );
  group('integration', () {
    late final MultiQueryWeb3Client client;

    setUpAll(() {
      client = MultiQueryWeb3Client(
        // public rpc https://chainlist.org/chain/5
        'https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
        Client(),
      );
    });

    // ignore: unnecessary_lambdas, https://github.com/dart-lang/linter/issues/2670
    tearDownAll(() => client.dispose());

    test('Multiquery request success', () async {
      final queries = [
        EthRPCQuery.getBalance(
          id: 2,
          address: EthereumAddress.fromHex(
            '0x81bEdCC7314baf7606b665909CeCDB4c68b180d6',
          ),
        ),
        EthRPCQuery.callContract(
          id: 1,
          contractCallParams: EthContractCallParams(
            contract: contract,
            function: contract.function('balanceOf'),
            params: [
              EthereumAddress.fromHex(
                '0x81bEdCC7314baf7606b665909CeCDB4c68b180d6',
              ),
            ],
          ),
        ),
        EthRPCQuery.getBlockInformation(
          block: BlockNum.exact(8302276),
          id: 3,
        )
      ];

      final responses = await client.multiqueryCall(queries);

      expect(responses, everyElement(isA<EthQueryResult>()));

      final balanceResult = (responses[0] as EthQueryResult);
      expect(
        balanceResult.id,
        equals(queries[0].id),
      );
      expect(balanceResult.result, greaterThan(BigInt.zero));

      final erc20BalanceResult = (responses[1] as EthQueryResult);
      expect(
        erc20BalanceResult.id,
        equals(queries[1].id),
      );
      // contract result azlways come in a list
      expect(erc20BalanceResult.result[0], greaterThan(BigInt.zero));

      final blockInfoResult = (responses[2] as EthQueryResult);
      expect(
        blockInfoResult.id,
        equals(queries[2].id),
      );
      expect(blockInfoResult.result, isA<BlockInformation>());
    });
  });

  group(
    'Query id assignment',
    () {
      late final MultiQueryWeb3Client client;

      setUpAll(() {
        client = MultiQueryWeb3Client(
          'mock url',
          MockClient(),
        );
      });
      test('Multiquery request arguments - ids assigned OK', () async {
        final queries = [
          EthRPCQuery.getBalance(
            address: EthereumAddress.fromHex(
              '0x81bEdCC7314baf7606b665909CeCDB4c68b180d6',
            ),
            id: 0,
          ),
          EthRPCQuery.getBalance(
            address: EthereumAddress.fromHex(
              '0x81bEdCC7314baf7606b665909CeCDB4c68b180d6',
            ),
            id: 1,
          ),
        ];

        expect(
          () {
            client.multiqueryCall(queries);
          },
          returnsNormally,
        );
      });
      test('Multiquery request arguments - no ids assigned', () async {
        final queries = [
          EthRPCQuery.getBalance(
            address: EthereumAddress.fromHex(
              '0x81bEdCC7314baf7606b665909CeCDB4c68b180d6',
            ),
          ),
          EthRPCQuery.getBalance(
            address: EthereumAddress.fromHex(
              '0x81bEdCC7314baf7606b665909CeCDB4c68b180d6',
            ),
          ),
        ];

        expect(
          () {
            client.multiqueryCall(queries);
          },
          returnsNormally,
        );
      });
      test('Multiquery request arguments - failure, bad rpc ids assignment',
          () async {
        final queries = [
          EthRPCQuery.getBalance(
            address: EthereumAddress.fromHex(
              '0x81bEdCC7314baf7606b665909CeCDB4c68b180d6',
            ),
            id: 4,
          ),
          EthRPCQuery.callContract(
            contractCallParams: EthContractCallParams(
              contract: contract,
              function: contract.function('balanceOf'),
              params: [
                EthereumAddress.fromHex(
                  '0x81bEdCC7314baf7606b665909CeCDB4c68b180d6',
                ),
              ],
            ),
            id: 1,
          ),
          EthRPCQuery.getBlockInformation(
            block: BlockNum.exact(8302276),
            // here we avoid specifying an id to make it throw
          )
        ];

        expect(
          client.multiqueryCall(queries),
          throwsArgumentError,
          reason:
              'As a bad assignment in querys id, calling this method should throw',
        );
      });
    },
  );
}

class MockClient extends BaseClient {
  StreamedResponse? nextResponse;
  BaseRequest? request;

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    this.request = request;
    return Future.value(
      nextResponse ??
          StreamedResponse(
            Stream.value(
              utf8.encode(
                '[{"id": "0", "jsonrpc": "2.0", "result": "0x1"},'
                '{"id": "1", "jsonrpc": "2.0", "result": "0x1"}]',
              ),
            ),
            200,
          ),
    );
  }
}

const erc20TestTokenAbi =
    '[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"},{"name":"_data","type":"bytes"}],"name":"transferAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_subtractedValue","type":"uint256"}],"name":"decreaseApproval","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_addedValue","type":"uint256"}],"name":"increaseApproval","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":false,"name":"data","type":"bytes"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]';
