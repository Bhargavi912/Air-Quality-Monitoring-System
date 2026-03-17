import 'package:latlong2/latlong.dart';

class FreeRouteModel {
  final int routeIndex;
  final String summary;
  final String distance;
  final String duration;
  final int averageAqi;
  final String aqiLevel;
  final String aqiEmoji;
  final int aqiColorHex;
  final int routeColorHex;
  final List<LatLng> routePoints;
  final List<AqiWaypointData> waypoints;
  final bool isRecommended;
  final String reason;
  final int rank;

  FreeRouteModel({
    required this.routeIndex,
    required this.summary,
    required this.distance,
    required this.duration,
    required this.averageAqi,
    required this.aqiLevel,
    required this.aqiEmoji,
    required this.aqiColorHex,
    required this.routeColorHex,
    required this.routePoints,
    required this.waypoints,
    this.isRecommended = false,
    this.reason = '',
    this.rank = 0,
  });

  FreeRouteModel copyWith({
    bool? isRecommended,
    int? routeColorHex,
    String? reason,
    int? rank,
    String? summary,
  }) {
    return FreeRouteModel(
      routeIndex: routeIndex,
      summary: summary ?? this.summary,
      distance: distance,
      duration: duration,
      averageAqi: averageAqi,
      aqiLevel: aqiLevel,
      aqiEmoji: aqiEmoji,
      aqiColorHex: aqiColorHex,
      routeColorHex: routeColorHex ?? this.routeColorHex,
      routePoints: routePoints,
      waypoints: waypoints,
      isRecommended: isRecommended ?? this.isRecommended,
      reason: reason ?? this.reason,
      rank: rank ?? this.rank,
    );
  }
}

class AqiWaypointData {
  final LatLng position;
  final int aqi;
  final double pm25;
  final String level;
  final int colorHex;
  final String townName;

  AqiWaypointData({
    required this.position,
    required this.aqi,
    required this.pm25,
    required this.level,
    required this.colorHex,
    this.townName = '',
  });
}