extension OrderExtensions on String {
  String get last6 {
    return substring(length - 6);
  }

  // convert {LARGE} to {Large}
  String toLarge() {
    if (isEmpty) return this;

    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
