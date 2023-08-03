import '../../credentials.dart';
import '../../crypto.dart';

class EthrDID {
  const EthrDID(this.did);

  factory EthrDID.fromPublicKeyEncoded({
    required EthPrivateKey credentials,
    required String chainNameOrId,
  }) {
    var did = 'did:ethr:$chainNameOrId:${bytesToHex(
      credentials.publicKey.getEncoded(),
      include0x: true,
    )}';
    return EthrDID(did);
  }

  factory EthrDID.fromEthereumAddress({
    required EthereumAddress address,
    required String chainNameOrId,
  }) {
    var did = 'did:ethr:$chainNameOrId:${address.hexEip55}';
    return EthrDID(did);
  }

  /// `identifier` is Ethereum address, public key or a full did:ethr representing Identity
  ///
  /// https://github.com/uport-project/ethr-did#configuration
  factory EthrDID.fromIdentifier({
    required String identifier,
    required String chainNameOrId,
  }) {
    var did = 'did:ethr:$chainNameOrId:$identifier';
    return EthrDID(did);
  }

  final String did;
}
