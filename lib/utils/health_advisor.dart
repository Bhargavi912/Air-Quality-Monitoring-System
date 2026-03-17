class HealthAdvisor {
  static Map<String, dynamic> getAdvice({
    required int age,
    required int aqi,
  }) {
    bool isSensitive = age < 12 || age > 60;

    if (aqi <= 50) {
      return {
        'level': 'Good',
        'emoji': '✅',
        'color': 0xFF4CAF50,
        'canGoOutside': true,
        'message': 'Air quality is great! Safe for everyone.',
        'advice': 'Enjoy outdoor activities freely.',
      };
    } else if (aqi <= 100) {
      return {
        'level': 'Moderate',
        'emoji': '⚠️',
        'color': 0xFFFFEB3B,
        'canGoOutside': !isSensitive,
        'message': isSensitive
            ? 'Be cautious outdoors. Air is moderate.'
            : 'Air is acceptable. Safe for most people.',
        'advice': isSensitive
            ? 'Limit outdoor time. Carry medication if needed.'
            : 'Normal outdoor activities are fine.',
      };
    } else if (aqi <= 150) {
      return {
        'level': 'Unhealthy for Sensitive',
        'emoji': '🟠',
        'color': 0xFFFF9800,
        'canGoOutside': false,
        'message': isSensitive
            ? 'NOT safe to go outside!'
            : 'Reduce prolonged outdoor exertion.',
        'advice': isSensitive
            ? 'Stay indoors. Use air purifier if available.'
            : 'Limit heavy outdoor exercise.',
      };
    } else if (aqi <= 200) {
      return {
        'level': 'Unhealthy',
        'emoji': '🔴',
        'color': 0xFFF44336,
        'canGoOutside': false,
        'message': 'Unhealthy air! Avoid outdoor activities.',
        'advice': 'Wear N95 mask if going outside is necessary.',
      };
    } else {
      return {
        'level': 'Very Unhealthy',
        'emoji': '🟣',
        'color': 0xFF9C27B0,
        'canGoOutside': false,
        'message': 'DANGEROUS! Stay indoors!',
        'advice': 'Seal windows. Use air purifier. Do NOT go outside.',
      };
    }
  }
}