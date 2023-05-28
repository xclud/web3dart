extension StringExtension on String {
  String stripOx() {
    if (startsWith('0x')) {
      return substring(2);
    }
    return this;
  }
}
