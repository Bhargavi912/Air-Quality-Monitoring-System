import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/air_quality_provider.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AirQualityProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA), // Clean off-white background
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(provider)),
              SliverToBoxAdapter(child: _buildContent(context, provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AirQualityProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B7BEC), Color(0xFF3867D6)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3867D6),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.timeline_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AQI Forecast', 
                    style: GoogleFonts.poppins(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        provider.locationName ?? 'Your Location',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
      ]),
    );
  }

  Widget _buildContent(BuildContext context, AirQualityProvider provider) {
    if (provider.isLoading && provider.currentAqi == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF4B7BEC)),
        ),
      );
    }

    if (provider.forecast == null || provider.forecast!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_queue_rounded, size: 60, color: Colors.blue.shade400),
            ),
            const SizedBox(height: 24),
            Text('Loading Forecast...', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Pull down to refresh data', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => provider.fetchAirQuality(),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B7BEC), 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ]),
        ),
      );
    }

    final forecastList = provider.forecast!;
    final next24h = forecastList.take(8).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      // Today's forecast header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today & Tomorrow', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text('Hourly AQI predictions', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Text(
                DateFormat('dd MMM').format(DateTime.now()),
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4B7BEC)),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 16),

      // Next 24h horizontal cards
      SizedBox(
        height: 170,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: next24h.length,
          itemBuilder: (_, i) {
            final item = next24h[i];
            final color = AppTheme.getAqiColor(item.standardAqi);
            final emoji = AppTheme.getAqiEmoji(item.standardAqi);
            final time = DateFormat('h:mm a').format(item.dateTime);
            final day = _getDayLabel(item.dateTime);

            return Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15), 
                    blurRadius: 15, 
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Stack(
                children: [
                  // Soft colored background at top
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        Text(time, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text(day, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Text(emoji, style: const TextStyle(fontSize: 28)),
                        const Spacer(),
                        Text('${item.standardAqi}',
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1.0)),
                        const SizedBox(height: 2),
                        Text(item.level, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                            overflow: TextOverflow.ellipsis),
                      ]
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 16),

      // Extended forecast
      if (forecastList.length > 8) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Text('Extended Forecast', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: (forecastList.length - 8).clamp(0, 16),
          itemBuilder: (_, i) {
            final item = forecastList[i + 8];
            final color = AppTheme.getAqiColor(item.standardAqi);
            final emoji = AppTheme.getAqiEmoji(item.standardAqi);
            final timeStr = DateFormat('h:mm a').format(item.dateTime);
            final dateStr = DateFormat('EEE, dd MMM').format(item.dateTime);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: IntrinsicHeight(
                  child: Row(children: [
                    // Colored indicator line
                    Container(
                      width: 6,
                      color: color,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start, 
                              children: [
                                Text(timeStr, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text(dateStr, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                              ]
                            ),
                            const Spacer(),
                            Text(emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Text('AQI', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Text('${item.standardAqi}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.level,
                                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color), 
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ],
      const SizedBox(height: 100), // Padding for bottom navigation bar
    ]);
  }

  String _getDayLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month) return 'Today';
    if (dt.day == now.day + 1 || (dt.day == 1 && dt.month != now.month)) return 'Tomorrow';
    return DateFormat('EEE').format(dt);
  }
}