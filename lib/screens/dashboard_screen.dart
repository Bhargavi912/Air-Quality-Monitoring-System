import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AirQualityProvider>();
      if (provider.currentAqi == null) {
        provider.fetchAirQuality();
      }
    });
  }

  String _getEmoji(int aqi) {
    if (aqi <= 50) return '😊';
    if (aqi <= 100) return '🙂';
    if (aqi <= 200) return '😐';
    if (aqi <= 300) return '😷';
    if (aqi <= 400) return '🤢';
    return '☠️';
  }

  String _getHealthMessage(int aqi) {
    if (aqi <= 50) return 'Air quality is excellent. Enjoy outdoor activities!';
    if (aqi <= 100) return 'Air quality is acceptable for most people.';
    if (aqi <= 200) return 'Sensitive groups may experience health effects.';
    if (aqi <= 300) return 'Everyone may begin to experience health effects.';
    if (aqi <= 400) return 'Health alert: serious effects for everyone.';
    return 'Health emergency: entire population affected.';
  }

  List<Color> _getGradientColors(int aqi) {
    if (aqi <= 50) return [const Color(0xFF4CAF50), const Color(0xFF81C784)];
    if (aqi <= 100) return [const Color(0xFFC6CC00), const Color(0xFFD4E157)];
    if (aqi <= 200) return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
    if (aqi <= 300) return [const Color(0xFFF44336), const Color(0xFFE57373)];
    if (aqi <= 400) return [const Color(0xFF9C27B0), const Color(0xFFBA68C8)];
    return [const Color(0xFF880000), const Color(0xFFB71C1C)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 Air Quality Monitoring System'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)]),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AirQualityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentAqi == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching air quality data...'),
                ],
              ),
            );
          }

          if (provider.error != null && provider.currentAqi == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAirQuality(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.currentAqi == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No data available'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAirQuality(),
                    child: const Text('Fetch Data'),
                  ),
                ],
              ),
            );
          }

          final aqi = provider.currentAqi!;
          final aqiVal = aqi.standardAqi;

          return RefreshIndicator(
            onRefresh: () => provider.fetchAirQuality(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ─── HEADER WITH AQI ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _getGradientColors(aqiVal),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Location
                        if (provider.locationName != null && provider.locationName!.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white70, size: 18),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  provider.locationName!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // AQI Circle
                        Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(40),
                            border: Border.all(color: Colors.white.withAlpha(80), width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, spreadRadius: 5)],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getEmoji(aqiVal), style: const TextStyle(fontSize: 30)),
                              Text(
                                '$aqiVal',
                                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Text('AQI', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          aqi.level,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getHealthMessage(aqiVal),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Pollutant row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _pollutantItem('PM2.5', aqi.pm25.toStringAsFixed(1)),
                              _pollutantItem('PM10', aqi.pm10.toStringAsFixed(1)),
                              _pollutantItem('CO', aqi.co.toStringAsFixed(0)),
                              _pollutantItem('NO₂', aqi.no2.toStringAsFixed(1)),
                              _pollutantItem('O₃', aqi.o3.toStringAsFixed(1)),
                              _pollutantItem('SO₂', aqi.so2.toStringAsFixed(1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── LIVE STATUS ───
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: provider.isLive ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.isLive ? 'Live • Auto-updating' : 'Offline',
                              style: TextStyle(
                                color: provider.isLive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              provider.lastUpdatedText,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => provider.fetchAirQuality(),
                              icon: const Icon(Icons.refresh, size: 20),
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ─── AQI TREND ───
                  if (provider.aqiTrend != 'stable')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: provider.aqiTrend == 'improving' ? Colors.green.shade50 : Colors.red.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                provider.aqiTrend == 'improving' ? Icons.trending_down : Icons.trending_up,
                                color: provider.aqiTrend == 'improving' ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.aqiTrend == 'improving'
                                    ? '📉 Air quality is improving!'
                                    : '📈 Air quality is worsening',
                                style: TextStyle(
                                  color: provider.aqiTrend == 'improving' ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // ─── AQI SCALE REFERENCE ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📊 Indian NAQI Scale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _scaleRow('Good', '0-50', const Color(0xFF4CAF50), aqiVal >= 0 && aqiVal <= 50),
                            _scaleRow('Satisfactory', '51-100', const Color(0xFFC6CC00), aqiVal >= 51 && aqiVal <= 100),
                            _scaleRow('Moderate', '101-200', const Color(0xFFFF9800), aqiVal >= 101 && aqiVal <= 200),
                            _scaleRow('Poor', '201-300', const Color(0xFFF44336), aqiVal >= 201 && aqiVal <= 300),
                            _scaleRow('Very Poor', '301-400', const Color(0xFF9C27B0), aqiVal >= 301 && aqiVal <= 400),
                            _scaleRow('Severe', '401-500', const Color(0xFF880000), aqiVal >= 401),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pollutantItem(String name, String value) {
    return Column(
      children: [
        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _scaleRow(String label, String range, Color color, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Row(
        children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
          Text(range, style: TextStyle(fontSize: 13, color: isActive ? color : Colors.grey)),
          if (isActive) ...[
            const Spacer(),
            Text('◄ Current', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}