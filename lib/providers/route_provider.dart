import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api_keys.dart';
import '../models/free_route_model.dart';

class RouteProvider extends ChangeNotifier {
  List<FreeRouteModel>? _routes;
  bool _isLoading = false;
  String? _error;
  int _selectedIndex = 0;
  String _loadingMsg = '';

  List<FreeRouteModel>? get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedRouteIndex => _selectedIndex;
  String get loadingMessage => _loadingMsg;

  FreeRouteModel? get selectedRoute {
    if (_routes != null &&
        _routes!.isNotEmpty &&
        _selectedIndex < _routes!.length) {
      return _routes![_selectedIndex];
    }
    return null;
  }

  FreeRouteModel? get recommendedRoute {
    if (_routes == null) return null;
    for (final r in _routes!) {
      if (r.isRecommended) return r;
    }
    return _routes!.isNotEmpty ? _routes!.first : null;
  }

  void selectRoute(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void clearRoutes() {
    _routes = null;
    _error = null;
    _selectedIndex = 0;
    _loadingMsg = '';
    notifyListeners();
  }

  static const List<int> _routeColors = [
    0xFF4CAF50,
    0xFF2196F3,
    0xFFFF9800,
    0xFF9C27B0,
    0xFFE91E63,
  ];

  static const List<String> indianCities = [
    'Hyderabad', 'Bangalore', 'Chennai', 'Mumbai', 'Delhi', 'Kolkata', 'Pune',
    'Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Kadapa',
    'Tirupati', 'Rajahmundry', 'Kakinada', 'Eluru', 'Ongole', 'Anantapur',
    'Proddatur', 'Nandyal', 'Adoni', 'Madanapalle', 'Chirala', 'Chittoor',
    'Warangal', 'Karimnagar', 'Nizamabad', 'Khammam', 'Mahbubnagar',
    'Badvel', 'Mydukur', 'Siddavatam', 'Rajampet', 'Pulivendla', 'Jammalamadugu',
    'Bengaluru', 'Mysuru', 'Hubli', 'Mangalore', 'Coimbatore', 'Madurai',
    'Salem', 'Kochi', 'Thiruvananthapuram', 'Lucknow', 'Jaipur', 'Ahmedabad',
    'Surat', 'Nagpur', 'Indore', 'Bhopal', 'Patna', 'Ranchi', 'Guwahati',
    'Chandigarh', 'Amritsar', 'Dehradun', 'Varanasi', 'Agra', 'Goa',
    'Srikakulam', 'Vizianagaram', 'Tenali', 'Hindupur', 'Ramagundam',
    'Nalgonda', 'Adilabad', 'Suryapet', 'Siddipet', 'Mancherial',
    'Yerraguntla', 'Porumamilla', 'Duvvur', 'Atluru', 'Bakarapeta',
    'Gopavaram',
  ];

  static const Map<String, String> _corrections = {
    'hyderbad': 'Hyderabad',
    'hydrabad': 'Hyderabad',
    'hiderabad': 'Hyderabad',
    'banglore': 'Bangalore',
    'bangalor': 'Bangalore',
    'bengalure': 'Bengaluru',
    'vizag': 'Visakhapatnam',
  };

  Future<void> searchRoutes({
    required String origin,
    required String destination,
    String travelMode = 'driving',
  }) async {
    _isLoading = true;
    _error = null;
    _routes = null;
    _selectedIndex = 0;
    notifyListeners();

    try {
      _loadingMsg = '📍 Finding "$origin"...';
      notifyListeners();
      final originLL = await _geocode(origin);

      _loadingMsg = '📍 Finding "$destination"...';
      notifyListeners();
      final destLL = await _geocode(destination);

      _loadingMsg = '🗺️ Finding all possible routes...';
      notifyListeners();

      List<Map<String, dynamic>> allRoutes = [];

      for (final tryProfile in ['driving', 'car']) {
        if (allRoutes.isNotEmpty) break;
        try {
          final url = Uri.parse(
            'https://router.project-osrm.org/route/v1/$tryProfile/'
            '${originLL.longitude},${originLL.latitude};'
            '${destLL.longitude},${destLL.latitude}'
            '?overview=full&alternatives=true&geometries=geojson&steps=true',
          );
          debugPrint('OSRM trying profile: $tryProfile');
          final res = await http.get(url).timeout(const Duration(seconds: 20));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
              allRoutes = List<Map<String, dynamic>>.from(data['routes']);
              debugPrint('OSRM success with $tryProfile: ${allRoutes.length} routes');
            }
          }
        } catch (e) {
          debugPrint('OSRM $tryProfile error: $e');
        }
      }

      if (allRoutes.isEmpty) {
        try {
          final url = Uri.parse(
            'https://router.project-osrm.org/route/v1/driving/'
            '${originLL.longitude},${originLL.latitude};'
            '${destLL.longitude},${destLL.latitude}'
            '?overview=full&geometries=geojson&steps=true',
          );
          final res = await http.get(url).timeout(const Duration(seconds: 20));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
              allRoutes = List<Map<String, dynamic>>.from(data['routes']);
            }
          }
        } catch (e) {
          debugPrint('OSRM fallback error: $e');
        }
      }

      if (allRoutes.isEmpty) {
        throw Exception(
            'No routes found between "$origin" and "$destination".\nPlease check the city names and try again.');
      }

      if (allRoutes.length < 3) {
        _loadingMsg = '🗺️ Finding alternative routes...';
        notifyListeners();

        final midLat = (originLL.latitude + destLL.latitude) / 2;
        final midLon = (originLL.longitude + destLL.longitude) / 2;
        final dLat = destLL.latitude - originLL.latitude;
        final dLon = destLL.longitude - originLL.longitude;

        for (final shift in [0.15, -0.15, 0.25, -0.25]) {
          if (allRoutes.length >= 4) break;
          try {
            final wp = LatLng(midLat + (-dLon * shift), midLon + (dLat * shift));
            final url = Uri.parse(
              'https://router.project-osrm.org/route/v1/driving/'
              '${originLL.longitude},${originLL.latitude};'
              '${wp.longitude},${wp.latitude};'
              '${destLL.longitude},${destLL.latitude}'
              '?overview=full&geometries=geojson&steps=true',
            );
            final res = await http.get(url).timeout(const Duration(seconds: 15));
            if (res.statusCode == 200) {
              final data = json.decode(res.body);
              if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
                final nr = data['routes'][0] as Map<String, dynamic>;
                final nd = (nr['distance'] is int)
                    ? (nr['distance'] as int).toDouble()
                    : nr['distance'] as double;
                bool diff = true;
                for (final ex in allRoutes) {
                  final ed = (ex['distance'] is int)
                      ? (ex['distance'] as int).toDouble()
                      : ex['distance'] as double;
                  if ((nd - ed).abs() < 5000) {
                    diff = false;
                    break;
                  }
                }
                if (diff) allRoutes.add(nr);
              }
            }
          } catch (e) {
            debugPrint('Alt route error: $e');
          }
        }
      }

      _loadingMsg = '🌍 Getting town names & air quality...';
      notifyListeners();

      List<FreeRouteModel> processed = [];
      for (int i = 0; i < allRoutes.length && i < 5; i++) {
        final route = allRoutes[i];
        final coords = route['geometry']['coordinates'] as List;
        List<LatLng> points = coords
            .map<LatLng>((c) => LatLng(
                  (c[1] is int) ? (c[1] as int).toDouble() : c[1] as double,
                  (c[0] is int) ? (c[0] as int).toDouble() : c[0] as double,
                ))
            .toList();

        double distM = (route['distance'] is int)
            ? (route['distance'] as int).toDouble()
            : route['distance'] as double;
        int durS = (route['duration'] is double)
            ? (route['duration'] as double).toInt()
            : route['duration'] as int;
        double km = distM / 1000;
        String dist = km < 1 ? '${distM.toInt()} m' : '${km.toStringAsFixed(1)} km';
        String dur = durS < 60
            ? '$durS sec'
            : durS < 3600
                ? '${(durS / 60).round()} min'
                : '${durS ~/ 3600}h ${(durS % 3600) ~/ 60}m';

        _loadingMsg = '🌍 Route ${i + 1}: Getting stations & AQI...';
        notifyListeners();

        List<AqiWaypointData> waypoints = await _sampleAqi(points);
        List<String> towns = waypoints
            .where((w) => w.townName.isNotEmpty && !w.townName.startsWith('Point'))
            .map<String>((w) => w.townName)
            .toList();
        String name = towns.length >= 2 ? towns.join(' → ') : _extractRouteName(route, i);

        int avgAqi = waypoints.isEmpty
            ? 0
            : (waypoints.map((w) => w.aqi).reduce((a, b) => a + b) / waypoints.length).round();
        final info = _aqiInfo(avgAqi);

        processed.add(FreeRouteModel(
          routeIndex: i,
          summary: name,
          distance: dist,
          duration: dur,
          averageAqi: avgAqi,
          aqiLevel: info['level'] as String,
          aqiEmoji: info['emoji'] as String,
          aqiColorHex: info['color'] as int,
          routeColorHex: _routeColors[i % _routeColors.length],
          routePoints: points,
          waypoints: waypoints,
        ));
      }

      List<FreeRouteModel> unique = [processed.first];
      for (int i = 1; i < processed.length; i++) {
        bool dup = false;
        for (final e in unique) {
          final d1 = double.tryParse(processed[i].distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          final d2 = double.tryParse(e.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          if ((d1 - d2).abs() < 5 && processed[i].summary == e.summary) {
            dup = true;
            break;
          }
        }
        if (!dup) unique.add(processed[i]);
      }
      processed = unique;

      processed.sort((a, b) => a.averageAqi.compareTo(b.averageAqi));
      for (int i = 0; i < processed.length; i++) {
        String reason;
        if (i == 0) {
          reason = '✅ Cleanest air with average AQI ${processed[i].averageAqi}';
          if (processed.length > 1) {
            reason += '\n🌬️ ${processed.last.averageAqi - processed[i].averageAqi} points better than worst route';
          }
        } else {
          int diff = processed[i].averageAqi - processed[0].averageAqi;
          reason = diff > 0
              ? '❌ AQI is $diff points WORSE than best route'
              : 'ℹ️ Similar air quality';
          if (processed[i].averageAqi > 300) {
            reason += '\n🔴 Very Poor';
          } else if (processed[i].averageAqi > 200) {
            reason += '\n🟠 Poor';
          } else if (processed[i].averageAqi > 100) {
            reason += '\n⚠️ Moderate';
          }
        }
        processed[i] = processed[i].copyWith(
          isRecommended: i == 0,
          routeColorHex: _routeColors[i % _routeColors.length],
          reason: reason,
          rank: i + 1,
        );
      }

      _routes = processed;
      if (_routes == null || _routes!.isEmpty) {
        _error = 'No routes found.';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    _loadingMsg = '';
    notifyListeners();
  }

  Future<LatLng> _geocode(String address) async {
    String query = address.trim();
    final qLower = query.toLowerCase();
    if (_corrections.containsKey(qLower)) {
      query = _corrections[qLower]!;
    }
    for (final city in indianCities) {
      if (city.toLowerCase() == qLower) {
        query = city;
        break;
      }
    }
    if (!query.contains(',') && !query.toLowerCase().contains('india')) {
      query = '$query, India';
    }
    debugPrint('Geocoding: "$query"');

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/direct'
        '?q=${Uri.encodeComponent(query)}&limit=5'
        '&appid=${ApiKeys.openWeatherMapKey}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        if (data.isNotEmpty) {
          Map<String, dynamic> best = data[0] as Map<String, dynamic>;
          for (final item in data) {
            if ((item['country'] as String?) == 'IN') {
              best = item as Map<String, dynamic>;
              break;
            }
          }
          final lat = (best['lat'] is int)
              ? (best['lat'] as int).toDouble()
              : best['lat'] as double;
          final lon = (best['lon'] is int)
              ? (best['lon'] as int).toDouble()
              : best['lon'] as double;
          debugPrint('Found: ${best['name']} -> $lat, $lon');
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('OWM geocode error: $e');
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1&countrycodes=in',
      );
      final res = await http
          .get(url, headers: {'User-Agent': 'AirQualityApp/1.0'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        if (data.isNotEmpty) {
          return LatLng(
            double.parse(data[0]['lat'].toString()),
            double.parse(data[0]['lon'].toString()),
          );
        }
      }
    } catch (e) {
      debugPrint('Nominatim error: $e');
    }

    throw Exception('Location not found: "$address"');
  }

  String _extractRouteName(Map<String, dynamic> route, int i) {
    try {
      final legs = route['legs'] as List;
      List<String> names = [];
      for (final leg in legs) {
        for (final step in (leg['steps'] as List)) {
          final name = (step['name'] as String?) ?? '';
          if (name.isNotEmpty &&
              name.length > 2 &&
              !names.contains(name) &&
              !name.toLowerCase().contains('unnamed')) {
            names.add(name);
          }
        }
      }
      if (names.isEmpty) return 'Route ${i + 1}';
      if (names.length <= 4) return names.join(' → ');
      final iv = names.length ~/ 3;
      return [names.first, names[iv], names[iv * 2], names.last].toSet().join(' → ');
    } catch (_) {}
    return 'Route ${i + 1}';
  }

  Future<List<AqiWaypointData>> _sampleAqi(List<LatLng> points) async {
    if (points.isEmpty) return [];
    List<AqiWaypointData> wps = [];
    List<int> indices = [0];
    for (int s = 1; s < 7; s++) {
      int idx = (points.length * s / 7).round().clamp(0, points.length - 1);
      if (!indices.contains(idx)) indices.add(idx);
    }
    if (!indices.contains(points.length - 1)) {
      indices.add(points.length - 1);
    }

    for (final idx in indices) {
      try {
        final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/air_pollution'
          '?lat=${points[idx].latitude}&lon=${points[idx].longitude}'
          '&appid=${ApiKeys.openWeatherMapKey}',
        )).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final d = json.decode(res.body);
          final item = d['list'][0];
          final pm25 = ((item['components']['pm2_5'] ?? 0) as num).toDouble();
          final std = _pm25ToAqi(pm25);
          final info = _aqiInfo(std);
          String town = await _reverseGeocode(points[idx].latitude, points[idx].longitude);
          wps.add(AqiWaypointData(
            position: points[idx],
            aqi: std,
            pm25: pm25,
            level: info['level'] as String,
            colorHex: info['color'] as int,
            townName: town,
          ));
        }
      } catch (e) {
        debugPrint('AQI error: $e');
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (wps.length > 2) {
      List<AqiWaypointData> unique = [wps.first];
      Set<String> seen = {wps.first.townName};
      for (int i = 1; i < wps.length - 1; i++) {
        if (!seen.contains(wps[i].townName)) {
          seen.add(wps[i].townName);
          unique.add(wps[i]);
        }
      }
      if (!seen.contains(wps.last.townName)) {
        unique.add(wps.last);
      } else {
        unique.add(AqiWaypointData(
          position: wps.last.position,
          aqi: wps.last.aqi,
          pm25: wps.last.pm25,
          level: wps.last.level,
          colorHex: wps.last.colorHex,
          townName: '${wps.last.townName} (End)',
        ));
      }
      return unique;
    }
    return wps;
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final res = await http.get(Uri.parse(
        'https://api.openweathermap.org/geo/1.0/reverse'
        '?lat=$lat&lon=$lon&limit=1'
        '&appid=${ApiKeys.openWeatherMapKey}',
      )).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        if (data.isNotEmpty) {
          final n = data[0]['name'] as String?;
          if (n != null && n.isNotEmpty) return n;
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    return 'Point ${lat.toStringAsFixed(2)}';
  }

  // Indian National AQI (NAQI) - PM2.5 breakpoints
  int _pm25ToAqi(double pm25) {
    if (pm25 <= 0) return 0;
    if (pm25 <= 30.0) {
      return (50.0 * pm25 / 30.0).round();
    } else if (pm25 <= 60.0) {
      return (51 + (49.0 * (pm25 - 30.0) / 30.0)).round();
    } else if (pm25 <= 90.0) {
      return (101 + (99.0 * (pm25 - 60.0) / 30.0)).round();
    } else if (pm25 <= 120.0) {
      return (201 + (99.0 * (pm25 - 90.0) / 30.0)).round();
    } else if (pm25 <= 250.0) {
      return (301 + (99.0 * (pm25 - 120.0) / 130.0)).round();
    } else {
      return (401 + (99.0 * (pm25 - 250.0) / 130.0)).round().clamp(401, 500);
    }
  }

  // Indian AQI categories and colors
  Map<String, dynamic> _aqiInfo(int aqi) {
    if (aqi <= 50) {
      return {'level': 'Good', 'emoji': '✅', 'color': 0xFF4CAF50};
    }
    if (aqi <= 100) {
      return {'level': 'Satisfactory', 'emoji': '😊', 'color': 0xFF8BC34A};
    }
    if (aqi <= 200) {
      return {'level': 'Moderate', 'emoji': '⚠️', 'color': 0xFFFFC107};
    }
    if (aqi <= 300) {
      return {'level': 'Poor', 'emoji': '🟠', 'color': 0xFFFF9800};
    }
    if (aqi <= 400) {
      return {'level': 'Very Poor', 'emoji': '🔴', 'color': 0xFFF44336};
    }
    return {'level': 'Severe', 'emoji': '🚨', 'color': 0xFF800000};
  }
}