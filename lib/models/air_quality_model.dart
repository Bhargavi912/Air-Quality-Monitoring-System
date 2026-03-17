class AirQualityModel {
  final int aqi;
  final double pm25;
  final double pm10;
  final double co;
  final double no2;
  final double o3;
  final double so2;
  final DateTime dateTime;

  AirQualityModel({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.co,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.dateTime,
  });

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    final item = json['list'][0];
    final components = item['components'];
    return AirQualityModel(
      aqi: item['main']['aqi'],
      pm25: (components['pm2_5'] ?? 0).toDouble(),
      pm10: (components['pm10'] ?? 0).toDouble(),
      co: (components['co'] ?? 0).toDouble(),
      no2: (components['no2'] ?? 0).toDouble(),
      o3: (components['o3'] ?? 0).toDouble(),
      so2: (components['so2'] ?? 0).toDouble(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
    );
  }

  factory AirQualityModel.fromForecastJson(Map<String, dynamic> item) {
    final components = item['components'];
    return AirQualityModel(
      aqi: item['main']['aqi'],
      pm25: (components['pm2_5'] ?? 0).toDouble(),
      pm10: (components['pm10'] ?? 0).toDouble(),
      co: (components['co'] ?? 0).toDouble(),
      no2: (components['no2'] ?? 0).toDouble(),
      o3: (components['o3'] ?? 0).toDouble(),
      so2: (components['so2'] ?? 0).toDouble(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
    );
  }

  /// Calculate Indian NAQI AQI based on PM2.5 (most dominant pollutant)
  /// This matches what aqi.in shows for India
  int get indianAqi {
    // Indian NAQI breakpoints for PM2.5 (24-hour average)
    // Using sub-index calculation for PM2.5
    final pm = pm25;

    if (pm <= 30) {
      return _interpolate(pm, 0, 30, 0, 50);
    } else if (pm <= 60) {
      return _interpolate(pm, 30, 60, 51, 100);
    } else if (pm <= 90) {
      return _interpolate(pm, 60, 90, 101, 200);
    } else if (pm <= 120) {
      return _interpolate(pm, 90, 120, 201, 300);
    } else if (pm <= 250) {
      return _interpolate(pm, 120, 250, 301, 400);
    } else {
      return _interpolate(pm, 250, 500, 401, 500);
    }
  }

  /// Calculate US EPA AQI based on PM2.5
  int get usAqi {
    final pm = pm25;

    if (pm <= 12.0) {
      return _interpolate(pm, 0, 12.0, 0, 50);
    } else if (pm <= 35.4) {
      return _interpolate(pm, 12.1, 35.4, 51, 100);
    } else if (pm <= 55.4) {
      return _interpolate(pm, 35.5, 55.4, 101, 150);
    } else if (pm <= 150.4) {
      return _interpolate(pm, 55.5, 150.4, 151, 200);
    } else if (pm <= 250.4) {
      return _interpolate(pm, 150.5, 250.4, 201, 300);
    } else {
      return _interpolate(pm, 250.5, 500.4, 301, 500);
    }
  }

  /// Standard AQI — use Indian scale
  int get standardAqi => indianAqi;

  /// AQI level label
  String get level {
    final aqiVal = standardAqi;
    if (aqiVal <= 50) return 'Good';
    if (aqiVal <= 100) return 'Satisfactory';
    if (aqiVal <= 200) return 'Moderate';
    if (aqiVal <= 300) return 'Poor';
    if (aqiVal <= 400) return 'Very Poor';
    return 'Severe';
  }

  /// AQI category (1-6 for color mapping)
  int get category {
    final aqiVal = standardAqi;
    if (aqiVal <= 50) return 1;
    if (aqiVal <= 100) return 2;
    if (aqiVal <= 200) return 3;
    if (aqiVal <= 300) return 4;
    if (aqiVal <= 400) return 5;
    return 6;
  }

  /// Linear interpolation for AQI calculation
  int _interpolate(
      double value, double cLow, double cHigh, int iLow, int iHigh) {
    if (cHigh == cLow) return iLow;
    return ((iHigh - iLow) / (cHigh - cLow) * (value - cLow) + iLow).round();
  }
}