part of 'package:web3dart/web3dart.dart';

class Sidecar {
  Sidecar({
    required this.blobs,
    required this.commitment,
    required this.proof,
  });

  final List<Uint8List> blobs;
  final List<Uint8List> commitment;
  final List<Uint8List> proof;
}
