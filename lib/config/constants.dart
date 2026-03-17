import 'package:flutter/material.dart';

class AqiConstants {
  /// Indian NAQI Scale (matches aqi.in)
  static Map<String, dynamic> getLevel(int aqi) {
    if (aqi <= 50) {
      return {
        'label': 'Good',
        'emoji': '✅',
        'color': const Color(0xFF4CAF50),
        'range': '0-50',
        'description': 'Minimal impact on health.',
      };
    } else if (aqi <= 100) {
      return {
        'label': 'Satisfactory',
        'emoji': '🟡',
        'color': const Color(0xFFC6CC00),
        'range': '51-100',
        'description': 'Minor breathing discomfort to sensitive people.',
      };
    } else if (aqi <= 200) {
      return {
        'label': 'Moderate',
        'emoji': '🟠',
        'color': const Color(0xFFFF9800),
        'range': '101-200',
        'description': 'Breathing discomfort to people with lung/heart disease.',
      };
    } else if (aqi <= 300) {
      return {
        'label': 'Poor',
        'emoji': '🔴',
        'color': const Color(0xFFF44336),
        'range': '201-300',
        'description': 'Breathing discomfort on prolonged exposure.',
      };
    } else if (aqi <= 400) {
      return {
        'label': 'Very Poor',
        'emoji': '🟣',
        'color': const Color(0xFF9C27B0),
        'range': '301-400',
        'description': 'Respiratory illness on prolonged exposure.',
      };
    } else {
      return {
        'label': 'Severe',
        'emoji': '🚨',
        'color': const Color(0xFF800000),
        'range': '401-500',
        'description': 'Affects healthy people. Serious impact on those with illness.',
      };
    }
  }
}