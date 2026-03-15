extension LocationExtensions on String {
  double get latitude {
    final parts = split(',');
    return double.parse(parts[0]);
  }

  double get longitude {
    final parts = split(',');
    return double.parse(parts[1]);
  }
}
