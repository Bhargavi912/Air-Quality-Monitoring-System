  /// Get full route path with town names: "Badvel → Atluru → Siddavatam → Kadapa"
  String _getRouteName(Map<String, dynamic> route, int i) {
    try {
      final legs = route['legs'] as List;
      List<String> townNames = [];

      for (final leg in legs) {
        final steps = leg['steps'] as List;
        for (final step in steps) {
          final name = (step['name'] as String?) ?? '';
          // Filter: only keep meaningful names (road names with towns)
          if (name.isNotEmpty && name.length > 2 && !townNames.contains(name)) {
            // Skip generic names
            if (!name.toLowerCase().contains('unnamed') &&
                !name.toLowerCase().contains('service') &&
                !name.toLowerCase().contains('link')) {
              townNames.add(name);
            }
          }
        }
      }

      if (townNames.isEmpty) return 'Route ${i + 1}';

      // Pick up to 4 key names spread across the route
      if (townNames.length <= 4) {
        return townNames.join(' → ');
      }

      // Take first, last, and 2 evenly spaced middle names
      final interval = townNames.length ~/ 3;
      final selected = [
        townNames.first,
        townNames[interval],
        townNames[interval * 2],
        townNames.last,
      ];

      // Remove duplicates while preserving order
      final unique = <String>[];
      for (final n in selected) {
        if (!unique.contains(n)) unique.add(n);
      }

      return unique.join(' → ');
    } catch (_) {}
    return 'Route ${i + 1}';
  }