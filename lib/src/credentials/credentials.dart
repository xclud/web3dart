import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/bytes.dart';
import 'package:pointycastle/ecc/api.dart' show ECPoint;
import 'package:web3dart/src/utils/equality.dart' as eq;

import '../../web3dart.dart' show Transaction;
import '../crypto/formatting.dart';
import '../crypto/keccak.dart';
import '../crypto/secp256k1.dart';
import '../crypto/secp256k1.dart' as secp256k1;
import '../utils/typed_data.dart';
import 'address.dart';

/// Anything that can sign payloads with a private key.
abstract class Credentials {
  static const _messagePrefix = '\u0019Ethereum Signed Message:\n';

  /// Whether these [Credentials] are safe to be copied to another isolate and
  /// can operate there.
  /// If this getter returns true, the client might chose to perform the
  /// expensive signing operations on another isolate.
  bool get isolateSafe => false;

  /// Loads the ethereum address specified by these credentials.
  Future<EthereumAddress> extractAddress() => Future.value(address);

  EthereumAddress get address;

  /// Signs the [payload] with a private key. The output will be like the
  /// bytes representation of the [eth_sign RPC method](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign),
  /// but without the "Ethereum signed message" prefix.
  /// The [payload] parameter contains the raw data, not a hash.
  Future<Uint8List> sign(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
    bool useKeccak256 = true,
  }) async {
    return signToUint8List(
      payload,
      chainId: chainId,
      isEIP1559: isEIP1559,
      useKeccak256: useKeccak256,
    );
  }

  /// Signs the [payload] with a private key. The output will be like the
  /// bytes representation of the [eth_sign RPC method](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign),
  /// but without the "Ethereum signed message" prefix.
  /// The [payload] parameter contains the raw data, not a hash.
  Uint8List signToUint8List(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
    bool useKeccak256 = true,
  }) {
    final signature = signToEcSignature(
      payload,
      chainId: chainId,
      isEIP1559: isEIP1559,
      useKeccak256: useKeccak256,
    );

    final r = padUint8ListTo32(unsignedIntToBytes(signature.r));
    final s = padUint8ListTo32(unsignedIntToBytes(signature.s));
    final v = unsignedIntToBytes(BigInt.from(signature.v));

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L63
    return uint8ListFromList(r + s + v);
  }

  /// Signs the [payload] with a private key and returns the obtained
  /// signature.
  Future<MsgSignature> signToSignature(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
    bool useKeccak256 = true,
  }) {
    return Future.value(
      signToEcSignature(
        payload,
        chainId: chainId,
        isEIP1559: isEIP1559,
        useKeccak256: useKeccak256,
      ),
    );
  }

  /// Signs the [payload] with a private key and returns the obtained
  /// signature.
  MsgSignature signToEcSignature(
    Uint8List payload, {
    int? chainId,
    bool isEIP1559 = false,
    bool useKeccak256 = true,
  }) =>
      throw UnimplementedError();

  /// Signs an Ethereum specific signature. This method is equivalent to
  /// [sign], but with a special prefix so that this method can't be used to
  /// sign, for instance, transactions.
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) {
    return Future.value(
      signPersonalMessageToUint8List(payload, chainId: chainId),
    );
  }

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

  Future<String> signTypedData(
    dynamic data, {
    TypedDataVersion version = TypedDataVersion.V1,
    int? chainId,
    bool isEIP1559 = false,
  }) async {
    final payload = data is String ? data : jsonEncode(data);
    final message =
        TypedDataUtil.hashMessage(jsonData: payload, version: version);
    final sig = await signToSignature(
      message,
      chainId: chainId,
      useKeccak256: false,
      isEIP1559: isEIP1559,
    );
    return SignatureUtil.concatSig(
      toBuffer(sig.r),
      toBuffer(sig.s),
      toBuffer(sig.v),
    );
  }

  Future<String> signPersonalTypedData(
    dynamic data, {
    TypedDataVersion version = TypedDataVersion.V1,
    int? chainId,
  }) async {
    final payload = data is String ? data : jsonEncode(data);
    final message =
        TypedDataUtil.hashMessage(jsonData: payload, version: version);
    final signed = await signPersonalMessage(message, chainId: chainId);
    return bytesToHex(signed, include0x: true);
  }

  String ecRecover({
    required String signature,
    required Uint8List message,
    required bool isPersonalSign,
  }) {
    return SignatureUtil.ecRecover(
      signature: signature,
      message: message,
      isPersonalSign: isPersonalSign,
    );
  }
}

/// Credentials where the [address] is known synchronously.
abstract class CredentialsWithKnownAddress extends Credentials {
  /// The ethereum address belonging to this credential.
  @override
  EthereumAddress get address;

  @override
  Future<EthereumAddress> extractAddress() async {
    return Future.value(address);
  }
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
    bool useKeccak256 = true,
  }) {
    final signature = secp256k1.sign(
      useKeccak256 ? keccak256(payload) : payload,
      privateKey,
    );

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
