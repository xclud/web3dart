part of web3dart;

enum EtherUnit {
  /// Wei, the smallest and atomic amount of Ether
  wei,

  /// kwei, 1000 wei
  kwei,

  /// Mwei, one million wei
  mwei,

  /// Gwei, one billion wei. Typically a reasonable unit to measure gas prices.
  gwei,

  /// szabo, 10^12 wei or 1 μEther
  szabo,

  /// finney, 10^15 wei or 1 mEther
  finney,

  /// 1 Ether
  ether,
}
