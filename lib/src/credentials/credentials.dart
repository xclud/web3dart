part of '../../web3dart.dart';

/// Anything that can sign payloads with a private key.
abstract class Credentials {
  static const _messagePrefix = '\u0019Ethereum Signed Message:\n';

  /// Whether these [Credentials] are safe to be copied to another isolate and
  /// can operate there.
  /// If this getter returns true, the client might chose to perform the
  /// expensive signing operations on another isolate.
  bool get isolateSafe => false;

  EthereumAddress get address;

  /// Signs the [payload] with a private key. The output will be like the
  /// bytes representation of the [eth_sign RPC method](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign),
  /// but without the "Ethereum signed message" prefix.
  /// The [payload] parameter contains the raw data, not a hash.
  Uint8List signToUint8List(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
  }) {
    final signature =
        signToEcSignature(payload, chainId: chainId, isEIP1559: isEIP1559);

    final r = padUint8ListTo32(unsignedIntToBytes(signature.r));
    final s = padUint8ListTo32(unsignedIntToBytes(signature.s));
    final v = unsignedIntToBytes(BigInt.from(signature.v));

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L63
    return uint8ListFromList(r + s + v);
  }

  /// Signs the [payload] with a private key and returns the obtained
  /// signature.
  MsgSignature signToEcSignature(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
  });

  /// Signs an Ethereum specific signature. This method is equivalent to
  /// [signToUint8List], but with a special prefix so that this method can't be used to
  /// sign, for instance, transactions.
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) {
    final prefix = _messagePrefix + payload.length.toString();
    final prefixBytes = ascii.encode(prefix);

    // will be a Uint8List, see the documentation of Uint8List.+
    final concat = uint8ListFromList(prefixBytes + payload);

    return signToUint8List(concat, chainId: chainId);
  }
}

/// Credentials where the [address] is known synchronously.
abstract class CredentialsWithKnownAddress extends Credentials {
  /// The ethereum address belonging to this credential.
  @override
  EthereumAddress get address;
}

/// Interface for [Credentials] that don't sign transactions locally, for
/// instance because the private key is not known to this library.
abstract class CustomTransactionSender extends Credentials {
  Future<String> sendTransaction(Transaction transaction);
}

/// Credentials that can sign payloads with an Ethereum private key.
class EthPrivateKey extends CredentialsWithKnownAddress {
  /// Creates a private key from a byte array representation.
  ///
  /// The bytes are interpreted as an unsigned integer forming the private key.
  EthPrivateKey(this.privateKey)
      : privateKeyInt = bytesToUnsignedInt(privateKey);

  /// Parses a private key from a hexadecimal representation.
  EthPrivateKey.fromHex(String hex) : this(hexToBytes(hex));

  /// Creates a private key from the underlying number.
  EthPrivateKey.fromInt(this.privateKeyInt)
      : privateKey = unsignedIntToBytes(privateKeyInt);

  /// Creates a new, random private key from the [random] number generator.
  ///
  /// For security reasons, it is very important that the random generator used
  /// is cryptographically secure. The private key could be reconstructed by
  /// someone else otherwise. Just using [Random()] is a very bad idea! At least
  /// use [Random.secure()].
  factory EthPrivateKey.createRandom(Random random) {
    final key = generateNewPrivateKey(random);
    return EthPrivateKey(intToBytes(key));
  }

  /// ECC's d private parameter.
  final BigInt privateKeyInt;
  final Uint8List privateKey;
  EthereumAddress? _cachedAddress;

  @override
  final bool isolateSafe = true;

  @override
  EthereumAddress get address {
    return _cachedAddress ??=
        EthereumAddress(publicKeyToAddress(privateKeyToPublic(privateKeyInt)));
  }

  /// Get the encoded public key in an (uncompressed) byte representation.
  Uint8List get encodedPublicKey => privateKeyToPublic(privateKeyInt);

  /// The public key corresponding to this private key.
  ECPoint get publicKey => (params.G * privateKeyInt)!;

  @override
  MsgSignature signToEcSignature(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
  }) {
    final signature = secp256k1.sign(keccak256(payload), privateKey);

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L26
    // be aware that signature.v already is recovery + 27
    int chainIdV;
    if (isEIP1559) {
      chainIdV = signature.v - 27;
    } else {
      chainIdV = chainId != null
          ? (signature.v - 27 + (chainId * 2 + 35))
          : signature.v;
    }
    return MsgSignature(signature.r, signature.s, chainIdV);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EthPrivateKey &&
          runtimeType == other.runtimeType &&
          eq.equals(privateKey, other.privateKey);

  @override
  int get hashCode => privateKey.hashCode;
}
