bool equals<T>(List<T>? left, List<T>? right) {
  if (identical(left, right)) return true;

  if (left == null || right == null) {
    return false;
  }

  if (left.length != right.length) {
    return false;
  }

  for (int i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }

  return true;
}
