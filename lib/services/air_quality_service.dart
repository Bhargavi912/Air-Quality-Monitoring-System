import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/air_quality_model.dart';

class AirQualityService {
  /// Fetch current air quality
  Future<AirQualityModel> getCurrentAirQuality(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/air_pollution'
      '?lat=$lat&lon=$lon'
      '&appid=${ApiKeys.openWeatherMapKey}',
    );

    debugPrint('Fetching AQI from: $url');
    final response = await http.get(url);
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch air quality data');
    }

    final data = json.decode(response.body);
    return AirQualityModel.fromJson(data);
  }

  /// Fetch 5-day forecast (3-hour intervals) — FREE from OpenWeatherMap
  Future<List<AirQualityModel>> getForecast(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/air_pollution/forecast'
      '?lat=$lat&lon=$lon'
      '&appid=${ApiKeys.openWeatherMapKey}',
    );

    debugPrint('Fetching forecast from: $url');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch forecast');
    }

    final data = json.decode(response.body);
    final list = data['list'] as List;

    return list.map<AirQualityModel>((item) {
      return AirQualityModel.fromForecastJson(item);
    }).toList();
  }
}