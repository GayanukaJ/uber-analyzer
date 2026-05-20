class TripData {
  final double price;
  final double distanceKm;
  final String title;
  final String rawText;
  final DateTime timestamp;

  TripData({
    required this.price,
    required this.distanceKm,
    required this.title,
    required this.rawText,
    required this.timestamp,
  });

  double get perKm => (price > 0 && distanceKm > 0) ? price / distanceKm : 0;

  RateCategory get rateCategory {
    if (perKm >= 80) return RateCategory.good;
    if (perKm >= 50) return RateCategory.average;
    return RateCategory.low;
  }

  factory TripData.fromMap(Map<dynamic, dynamic> map) {
    return TripData(
      price: (map['price'] as num?)?.toDouble() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      title: map['title'] as String? ?? 'Trip Request',
      rawText: map['rawText'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Parse from the CSV line stored in SharedPreferences
  /// Format: timestamp,price,distanceKm,perKm
  factory TripData.fromHistoryLine(String line) {
    final parts = line.split(',');
    return TripData(
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[0]) ?? 0),
      price: double.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      distanceKm: double.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
      title: 'Trip Request',
      rawText: '',
    );
  }
}

enum RateCategory { good, average, low }

extension RateCategoryExt on RateCategory {
  String get label {
    switch (this) {
      case RateCategory.good:    return '✓ Good Rate';
      case RateCategory.average: return '~ Average Rate';
      case RateCategory.low:     return '✗ Low Rate';
    }
  }

  int get color {
    switch (this) {
      case RateCategory.good:    return 0xFF00C853;
      case RateCategory.average: return 0xFFFFD600;
      case RateCategory.low:     return 0xFFFF5252;
    }
  }
}
