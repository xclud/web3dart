part of web3dart;

/// Utility class to easily convert amounts of Ether into different units of
/// quantities.
class EtherAmount {
  const EtherAmount.inWei(this._value);

  EtherAmount.zero() : this.inWei(BigInt.zero);

  /// Constructs an amount of Ether by a unit and its amount. [amount] can
  /// either be a base10 string, an int or a BigInt.
  @Deprecated(
    'Please use fromInt, fromBigInt or fromBase10String.',
  )
  factory EtherAmount.fromUnitAndValue(EtherUnit unit, dynamic amount) {
    BigInt parsedAmount;

    if (amount is BigInt) {
      parsedAmount = amount;
    } else if (amount is int) {
      parsedAmount = BigInt.from(amount);
    } else if (amount is String) {
      parsedAmount = BigInt.parse(amount);
    } else {
      throw ArgumentError('Invalid type, must be BigInt, string or int');
    }

    return EtherAmount.inWei(parsedAmount * _factors[unit]!);
  }

  /// Constructs an amount of Ether by a unit and its amount.
  factory EtherAmount.fromInt(EtherUnit unit, int amount) {
    final wei = _factors[unit]! * BigInt.from(amount);

    return EtherAmount.inWei(wei);
  }

  /// Constructs an amount of Ether by a unit and its amount.
  factory EtherAmount.fromBigInt(EtherUnit unit, BigInt amount) {
    final wei = _factors[unit]! * amount;

    return EtherAmount.inWei(wei);
  }

  /// Constructs an amount of Ether by a unit and its amount.
  factory EtherAmount.fromBase10String(EtherUnit unit, String amount) {
    final wei = _factors[unit]! * BigInt.parse(amount);

    return EtherAmount.inWei(wei);
  }

  /// Gets the value of this amount in the specified unit as a whole number.
  /// **WARNING**: For all units except for [EtherUnit.wei], this method will
  /// discard the remainder occurring in the division, making it unsuitable for
  /// calculations or storage. You should store and process amounts of ether by
  /// using a BigInt storing the amount in wei.
  BigInt getValueInUnitBI(EtherUnit unit) => _value ~/ _factors[unit]!;

  static final Map<EtherUnit, BigInt> _factors = {
    EtherUnit.wei: BigInt.one,
    EtherUnit.kwei: BigInt.from(10).pow(3),
    EtherUnit.mwei: BigInt.from(10).pow(6),
    EtherUnit.gwei: BigInt.from(10).pow(9),
    EtherUnit.szabo: BigInt.from(10).pow(12),
    EtherUnit.finney: BigInt.from(10).pow(15),
    EtherUnit.ether: BigInt.from(10).pow(18),
  };

  final BigInt _value;

  BigInt get getInWei => _value;
  BigInt get getInEther => getValueInUnitBI(EtherUnit.ether);

  /// Gets the value of this amount in the specified unit. **WARNING**: Due to
  /// rounding errors, the return value of this function is not reliable,
  /// especially for larger amounts or smaller units. While it can be used to
  /// display the amount of ether in a human-readable format, it should not be
  /// used for anything else.
  double getValueInUnit(EtherUnit unit) {
    final factor = _factors[unit]!;
    final value = _value ~/ factor;
    final remainder = _value.remainder(factor);

    return value.toInt() + (remainder.toInt() / factor.toInt());
  }

  @override
  String toString() {
    return 'EtherAmount: $getInWei wei';
  }

  @override
  int get hashCode => getInWei.hashCode;

  @override
  bool operator ==(Object other) =>
      other is EtherAmount && other.getInWei == getInWei;
}
