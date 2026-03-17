import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/air_quality_model.dart';

class AirQualityProvider extends ChangeNotifier {
  AirQualityModel? _currentAqi;
  AirQualityModel? _previousAqi;
  List<AirQualityModel>? _forecast;
  String? _locationName;
  String? _error;
  bool _isLoading = false;
  bool _isLive = false;
  DateTime? _lastUpdated;
  Timer? _autoRefreshTimer;
  Timer? _tickTimer;
  int _secondsSinceUpdate = 0;
  double? _lastLat;
  double? _lastLon;

  // ===== GETTERS =====
  AirQualityModel? get currentAqi => _currentAqi;
  AirQualityModel? get previousAqi => _previousAqi;
  List<AirQualityModel>? get forecast => _forecast;
  String? get locationName => _locationName;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLive => _isLive;
  DateTime? get lastUpdated => _lastUpdated;
  int get secondsSinceUpdate => _secondsSinceUpdate;

  String get lastUpdatedText {
    if (_lastUpdated == null) return 'Never';
    if (_secondsSinceUpdate < 5) return 'Just now';
    if (_secondsSinceUpdate < 60) return '${_secondsSinceUpdate}s ago';
    final minutes = _secondsSinceUpdate ~/ 60;
    if (minutes < 60) return '${minutes}m ago';
    return '${minutes ~/ 60}h ${minutes % 60}m ago';
  }

  String get aqiTrend {
    if (_previousAqi == null || _currentAqi == null) return 'stable';
    final diff = _currentAqi!.standardAqi - _previousAqi!.standardAqi;
    if (diff > 5) return 'worsening';
    if (diff < -5) return 'improving';
    return 'stable';
  }

  void startLiveMode() {
    if (_isLive) return;
    _isLive = true;
    notifyListeners();

    // Delay first fetch to let browser settle
    Future.delayed(const Duration(seconds: 2), () {
      fetchAirQuality();
    });

    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchAirQuality(silent: true);
    });

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsSinceUpdate++;
      notifyListeners();
    });
  }

  void stopLiveMode() {
    _isLive = false;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
    notifyListeners();
  }

  Future<void> fetchAirQuality({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // Step 1: Get location
      double lat;
      double lon;

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        debugPrint('Location service enabled: $serviceEnabled');

        LocationPermission permission = await Geolocator.checkPermission();
        debugPrint('Location permission: $permission');

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permission denied. Please allow location access.');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permission permanently denied. Enable in browser settings.');
        }

        debugPrint('Getting current position...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Location timeout. Please refresh.');
          },
        );
        lat = position.latitude;
        lon = position.longitude;
        _lastLat = lat;
        _lastLon = lon;
        debugPrint('Got position: $lat, $lon');
      } catch (e) {
        // If we have a previous position, use it
        if (_lastLat != null && _lastLon != null) {
          lat = _lastLat!;
          lon = _lastLon!;
          debugPrint('Using last known position: $lat, $lon');
        } else {
          rethrow;
        }
      }

      // Step 2: Get location name (won't crash if it fails)
      if (_locationName == null || _locationName!.contains(',') == false) {
        await _getLocationName(lat, lon);
      }

      // Step 3: Fetch AQI
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/air_pollution'
        '?lat=$lat&lon=$lon'
        '&appid=${ApiKeys.openWeatherMapKey}',
      );

      debugPrint('Fetching AQI from: $url');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('AQI request timed out'),
      );
      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch air quality data');
      }

      final data = json.decode(response.body);
      final aqi = AirQualityModel.fromJson(data);

      if (_currentAqi != null) {
        _previousAqi = _currentAqi;
      }

      _currentAqi = aqi;
      _error = null;
      _lastUpdated = DateTime.now();
      _secondsSinceUpdate = 0;

      // Step 4: Fetch forecast (optional — won't crash if fails)
      try {
        final forecastUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/air_pollution/forecast'
          '?lat=$lat&lon=$lon'
          '&appid=${ApiKeys.openWeatherMapKey}',
        );

        final forecastRes = await http.get(forecastUrl).timeout(
          const Duration(seconds: 10),
        );
        if (forecastRes.statusCode == 200) {
          final forecastData = json.decode(forecastRes.body);
          final forecastList = forecastData['list'] as List;
          _forecast = forecastList.map<AirQualityModel>((item) {
            return AirQualityModel.fromForecastJson(item);
          }).toList();
          debugPrint('Forecast loaded: ${_forecast!.length} items');
        }
      } catch (e) {
        debugPrint('Forecast failed (optional): $e');
      }
    } catch (e) {
      debugPrint('Error in fetchAirQuality: $e');
      // Only show error if we have NO data at all
      if (_currentAqi == null && !silent) {
        _error = e.toString().replaceAll('Exception: ', '');
      }
      // If we already have data, keep showing it (don't replace with error)
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _getLocationName(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/reverse'
        '?lat=$lat&lon=$lon&limit=1'
        '&appid=${ApiKeys.openWeatherMapKey}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final place = data[0];
          final name = place['name'] ?? '';
          final state = place['state'] ?? '';
          final country = place['country'] ?? '';

          if (name.isNotEmpty && state.isNotEmpty) {
            _locationName = '$name, $state, $country';
          } else if (name.isNotEmpty) {
            _locationName = '$name, $country';
          } else {
            _locationName = '$state, $country';
          }
          debugPrint('Location: $_locationName');
          return;
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    // Fallback
    _locationName = '${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}';
  }

  @override
  void dispose() {
    stopLiveMode();
    super.dispose();
  }
}