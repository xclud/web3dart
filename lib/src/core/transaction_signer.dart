part of 'package:web3dart/web3dart.dart';

class _SigningInput {
  _SigningInput({
    required this.transaction,
    required this.credentials,
    this.chainId,
  });

  final Transaction transaction;
  final Credentials credentials;
  final int? chainId;
}

Future<_SigningInput> _fillMissingData({
  required Credentials credentials,
  required Transaction transaction,
  int? chainId,
  bool loadChainIdFromNetwork = false,
  Web3Client? client,
}) async {
  if (loadChainIdFromNetwork && chainId != null) {
    throw ArgumentError(
      "You can't specify loadChainIdFromNetwork and specify a custom chain id!",
    );
  }

  final sender = transaction.from ?? credentials.address;
  var gasPrice = transaction.gasPrice;

  if (client == null &&
      (transaction.nonce == null ||
          transaction.maxGas == null ||
          loadChainIdFromNetwork ||
          (!transaction.isEIP1559 && gasPrice == null))) {
    throw ArgumentError('Client is required to perform network actions');
  }

  if (!transaction.isEIP1559 && !transaction.isEIP4844 && gasPrice == null) {
    gasPrice = await client!.getGasPrice();
  }

  var maxFeePerGas = transaction.maxFeePerGas;
  var maxPriorityFeePerGas = transaction.maxPriorityFeePerGas;

  if (transaction.isEIP1559 || transaction.isEIP4844) {
    maxPriorityFeePerGas ??= await _getMaxPriorityFeePerGas();
    maxFeePerGas ??= await _getMaxFeePerGas(
      client!,
      maxPriorityFeePerGas.getInWei,
    );
  }

  final nonce = transaction.nonce ??
      await client!
          .getTransactionCount(sender, atBlock: const BlockNum.pending());

  final maxGas = transaction.maxGas ??
      await client!
          .estimateGas(
            sender: sender,
            to: transaction.to,
            data: transaction.data,
            value: transaction.value,
            gasPrice: gasPrice,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            maxFeePerGas: maxFeePerGas,
          )
          .then((bigInt) => bigInt.toInt());

  // apply default values to null fields
  final modifiedTransaction = transaction.copyWith(
    value: transaction.value ?? EtherAmount.zero(),
    maxGas: maxGas,
    from: sender,
    data: transaction.data ?? Uint8List(0),
    gasPrice: gasPrice,
    nonce: nonce,
    maxPriorityFeePerGas: maxPriorityFeePerGas,
    maxFeePerGas: maxFeePerGas,
  );

  int resolvedChainId;
  if (!loadChainIdFromNetwork) {
    resolvedChainId = chainId!;
  } else {
    resolvedChainId = await client!.getNetworkId();
  }

  return _SigningInput(
    transaction: modifiedTransaction,
    credentials: credentials,
    chainId: resolvedChainId,
  );
}

Uint8List prependTransactionType(int type, Uint8List transaction) {
  return Uint8List(transaction.length + 1)
    ..[0] = type
    ..setAll(1, transaction);
}

Uint8List signTransactionRaw(
  Transaction transaction,
  Credentials c, {
  int? chainId = 1,
}) {
  final encoded = transaction.getUnsignedSerialized(chainId: chainId);
  final signature = c.signToEcSignature(
    encoded,
    chainId: chainId,
    isEIP1559: transaction.isEIP1559,
    isEIP4844: transaction.isEIP4844,
  );

  if (transaction.isEIP1559 && chainId != null) {
    return uint8ListFromList(
      rlp.encode(
        _encodeEIP1559ToRlp(transaction, signature, BigInt.from(chainId)),
      ),
    );
  } else if (transaction.isEIP4844 && chainId != null) {
    final values =
        _wrap4844ToRlpValues(transaction, signature, BigInt.from(chainId));

    final encode = rlp.encode(values);
    return uint8ListFromList(encode);
  }
  return uint8ListFromList(rlp.encode(_encodeToRlp(transaction, signature)));
}

List<dynamic> _encodeEIP1559ToRlp(
  Transaction transaction,
  MsgSignature? signature,
  BigInt chainId,
) {
  final list = [
    chainId,
    transaction.nonce,
    transaction.maxPriorityFeePerGas!.getInWei,
    transaction.maxFeePerGas!.getInWei,
    transaction.maxGas,
  ];

  if (transaction.to != null) {
    list.add(transaction.to!.addressBytes);
  } else {
    list.add('');
  }

  list
    ..add(transaction.value?.getInWei)
    ..add(transaction.data);

  list.add([]); // access list

  if (signature != null) {
    list
      ..add(signature.v)
      ..add(signature.r)
      ..add(signature.s);
  }

  return list;
}

List<dynamic> _encodeEIP4844ToRlpWithSidecar(
  Transaction transaction,
  MsgSignature? signature,
  BigInt chainId,
) {
  final list = [
    chainId,
    transaction.nonce,
    transaction.maxPriorityFeePerGas!.getInWei,
    transaction.maxFeePerGas!.getInWei,
    transaction.maxGas,
  ];

  if (transaction.to != null) {
    list.add(transaction.to!.addressBytes);
  } else {
    list.add('');
  }

  list
    ..add(transaction.value?.getInWei)
    ..add(transaction.data);

  list.add([]); // access list

  list.add(transaction.maxFeePerBlobGas!.getInWei);
  list.add(transaction.blobVersionedHashes!);

  if (signature != null) {
    list
      ..add(signature.v)
      ..add(signature.r)
      ..add(signature.s);
  }
  return list;
}

// https://github.com/hyperledger/web3j/blob/main/crypto/src/main/java/org/web3j/crypto/transaction/type/Transaction4844.java
// [chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, to, value, data, access_list, max_fee_per_blob_gas, blob_versioned_hashes, y_parity, r, s]
List<dynamic> _wrap4844ToRlpValues(
  Transaction transaction,
  MsgSignature? signature,
  BigInt chainId,
) {
  final resultTx = [];

  resultTx.add(chainId);
  resultTx.add(transaction.nonce);
  resultTx.add(transaction.maxPriorityFeePerGas!.getInWei);
  resultTx.add(transaction.maxFeePerGas!.getInWei);
  resultTx.add(transaction.maxGas);
  if (transaction.to != null) {
    resultTx.add(transaction.to!.addressBytes);
  } else {
    resultTx.add('');
  }

  resultTx.add(transaction.value!.getInWei);
  resultTx.add(transaction.data);
  resultTx.add([]);
  resultTx.add(transaction.maxFeePerBlobGas!.getInWei);
  resultTx.add(transaction.blobVersionedHashes);
  if (signature != null) {
    resultTx.add(signature.v);
    resultTx.add(signature.r);
    resultTx.add(signature.s);
  }

  final result = [];
  result.add(resultTx);

  if (transaction.sidecar != null) {
    result.add(transaction.sidecar!.blobs);
    result.add(transaction.sidecar!.commitment);
    result.add(transaction.sidecar!.proof);
  }

  return result;
}

List<dynamic> _encodeToRlp(Transaction transaction, MsgSignature? signature) {
  final list = [
    transaction.nonce,
    transaction.gasPrice?.getInWei,
    transaction.maxGas,
  ];

  if (transaction.to != null) {
    list.add(transaction.to!.addressBytes);
  } else {
    list.add('');
  }

  list
    ..add(transaction.value?.getInWei)
    ..add(transaction.data);

  if (signature != null) {
    list
      ..add(signature.v)
      ..add(signature.r)
      ..add(signature.s);
  }

  return list;
}

Future<EtherAmount> _getMaxPriorityFeePerGas() {
  // We may want to compute this more accurately in the future,
  // using the formula "check if the base fee is correct".
  // See: https://eips.ethereum.org/EIPS/eip-1559
  return Future.value(EtherAmount.inWei(BigInt.from(1000000000)));
}

// Max Fee = (2 * Base Fee) + Max Priority Fee
Future<EtherAmount> _getMaxFeePerGas(
  Web3Client client,
  BigInt maxPriorityFeePerGas,
) async {
  final blockInformation = await client.getBlockInformation();
  final baseFeePerGas = blockInformation.baseFeePerGas;

  if (baseFeePerGas == null) {
    return EtherAmount.zero();
  }

  return EtherAmount.inWei(
    baseFeePerGas.getInWei * BigInt.from(2) + maxPriorityFeePerGas,
  );
}
