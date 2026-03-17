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
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(provider)),
            SliverToBoxAdapter(child: _buildContent(context, provider)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AirQualityProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.timeline_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text('AQI Forecast', style: GoogleFonts.rajdhani(
                fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 4),
          Text(provider.locationName ?? 'Your Location',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60)),
        ]),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AirQualityProvider provider) {
    if (provider.isLoading && provider.currentAqi == null) {
      return const Padding(padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)));
    }

    if (provider.forecast == null || provider.forecast!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
          ),
          child: Column(children: [
            Icon(Icons.cloud_queue_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Loading Forecast...', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Pull down to refresh', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGrey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => provider.fetchAirQuality(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
    }

    final forecastList = provider.forecast!;
    final next24h = forecastList.take(8).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Today's forecast header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(children: [
          Text('Today & Tomorrow', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
        ]),
      ),

      // Next 24h horizontal cards with ACTUAL TIMES
      SizedBox(
        height: 155,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: next24h.length,
          itemBuilder: (_, i) {
            final item = next24h[i];
            final color = AppTheme.getAqiColor(item.standardAqi);
            final emoji = AppTheme.getAqiEmoji(item.standardAqi);
            final time = DateFormat('h:mm a').format(item.dateTime);
            final day = _getDayLabel(item.dateTime);

            return Container(
              width: 110,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8)],
                border: Border.all(color: color.withAlpha(40)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(time, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                Text(day, style: GoogleFonts.poppins(fontSize: 9, color: AppTheme.textGrey)),
                const SizedBox(height: 6),
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text('${item.standardAqi}',
                    style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.w700, color: color)),
                Text(item.level, style: GoogleFonts.poppins(fontSize: 8, color: color),
                    overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        ),
      ),

      // Extended forecast with actual dates/times
      if (forecastList.length > 8) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text('Extended Forecast', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: (forecastList.length - 8).clamp(0, 16),
          itemBuilder: (_, i) {
            final item = forecastList[i + 8];
            final color = AppTheme.getAqiColor(item.standardAqi);
            final emoji = AppTheme.getAqiEmoji(item.standardAqi);
            final timeStr = DateFormat('h:mm a').format(item.dateTime);
            final dateStr = DateFormat('EEE, dd MMM').format(item.dateTime);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 6)],
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(timeStr, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  Text(dateStr, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGrey)),
                ]),
                const Spacer(),
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20), borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('AQI ${item.standardAqi}',
                      style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 80, child: Text(item.level,
                    style: GoogleFonts.poppins(fontSize: 11, color: color), overflow: TextOverflow.ellipsis)),
              ]),
            );
          },
        ),
      ],
      const SizedBox(height: 100),
    ]);
  }

  String _getDayLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) return 'Today';
    if (dt.day == now.day + 1) return 'Tomorrow';
    return DateFormat('EEE').format(dt);
  }
}