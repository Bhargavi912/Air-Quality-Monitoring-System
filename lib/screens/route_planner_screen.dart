import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';
import '../config/api_keys.dart';
import '../providers/route_provider.dart';
import '../models/free_route_model.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RouteProvider(),
      child: const _RoutePlannerPages(),
    );
  }
}

class _RoutePlannerPages extends StatefulWidget {
  const _RoutePlannerPages();

  @override
  State<_RoutePlannerPages> createState() => _RoutePlannerPagesState();
}

class _RoutePlannerPagesState extends State<_RoutePlannerPages> {
  String _originText = '';
  String _destText = '';
  String _travelMode = 'driving';
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RouteProvider>();

    if (_page == 2 && prov.selectedRoute != null) {
      return _FullMapPage(
        route: prov.selectedRoute!,
        travelMode: _travelMode,
        origin: _originText,
        destination: _destText,
        onBack: () => setState(() => _page = 1),
      );
    }

    if (_page == 1 && prov.routes != null && prov.routes!.isNotEmpty) {
      return _buildRoutesPage(context, prov);
    }

    return _buildInputPage(context, prov);
  }

  // ==================== PAGE 1: INPUT ====================
  Widget _buildInputPage(BuildContext context, RouteProvider prov) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.blueGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.route_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('Route Planner',
                    style: GoogleFonts.rajdhani(
                        fontSize: 28, fontWeight: FontWeight.w700)),
              ),
              Center(
                child: Text('Find the cleanest air quality route',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.textGrey)),
              ),
              const SizedBox(height: 30),

              // Source
              Text('Source',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _CityAutocompleteField(
                initialValue: _originText,
                hint: 'e.g. Kadapa',
                icon: Icons.my_location,
                iconColor: Colors.green,
                onTextChanged: (val) {
                  _originText = val;
                },
              ),
              const SizedBox(height: 16),

              // Destination
              Text('Destination',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _CityAutocompleteField(
                initialValue: _destText,
                hint: 'e.g. Hyderabad',
                icon: Icons.location_on,
                iconColor: Colors.red,
                onTextChanged: (val) {
                  _destText = val;
                },
                onSubmitted: () => _doSearch(context),
              ),
              const SizedBox(height: 20),

              // Travel mode
              Text('Travel Mode',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
  children: [
    _buildModeBtn('🚗', 'Car', 'car'),
    _buildModeBtn('🚌', 'Bus', 'bus'),
    _buildModeBtn('🚴', 'Bike', 'cycling'),
    _buildModeBtn('🚶', 'Walk', 'walking'),
  ],
),
              const SizedBox(height: 24),

              // Error
              if (prov.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(prov.error!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade700)),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: prov.clearRoutes),
                    ],
                  ),
                ),

              // Loading or Search button
              if (prov.isLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue, strokeWidth: 3),
                      ),
                      const SizedBox(height: 14),
                      Text(prov.loadingMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppTheme.textGrey)),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _doSearch(context),
                    icon: const Icon(Icons.explore_rounded, size: 22),
                    label: Text('Find Routes',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _doSearch(BuildContext context) {
    final o = _originText.trim();
    final d = _destText.trim();
    if (o.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter source city')));
      return;
    }
    if (d.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter destination city')));
      return;
    }
    FocusScope.of(context).unfocus();
    debugPrint('SEARCHING: "$o" to "$d"');
    final prov = context.read<RouteProvider>();
    prov
        .searchRoutes(origin: o, destination: d, travelMode: _travelMode)
        .then((_) {
      if (prov.routes != null && prov.routes!.isNotEmpty) {
        setState(() => _page = 1);
      }
    });
  }

  Widget _buildModeBtn(String emoji, String label, String mode) {
    final sel = _travelMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _travelMode = mode),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppTheme.primaryBlue.withAlpha(15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? AppTheme.primaryBlue : Colors.grey.shade200,
                width: sel ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel
                          ? AppTheme.primaryBlue
                          : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== PAGE 2: ROUTES LIST ====================
  Widget _buildRoutesPage(BuildContext context, RouteProvider prov) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _page = 0)),
        title: Text('$_originText → $_destText',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.route_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${prov.routes!.length} Routes Found',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text('Sorted by air quality • Best first',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                      '🏆 Best AQI: ${prov.routes!.first.averageAqi}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prov.routes!.length,
              itemBuilder: (_, i) {
                final r = prov.routes![i];
                return _buildRouteCard(r, () {
                  prov.selectRoute(i);
                  setState(() => _page = 2);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(FreeRouteModel route, VoidCallback onSelect) {
    final isBest = route.isRecommended;
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color:
                  isBest ? Colors.green.shade300 : Colors.grey.shade200,
              width: isBest ? 2 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route name + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                      color: Color(route.routeColorHex),
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(route.summary,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isBest
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isBest
                            ? Colors.green.shade200
                            : Colors.grey.shade300),
                  ),
                  child: Text(isBest ? '🏆 BEST' : '#${route.rank}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isBest
                              ? Colors.green.shade700
                              : Colors.grey.shade600)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // AQI + Distance + Duration
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Color(route.aqiColorHex).withAlpha(20),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(route.aqiEmoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text('AQI ${route.averageAqi}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(route.aqiColorHex))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(route.aqiLevel,
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(route.aqiColorHex))),
                const Spacer(),
                Icon(Icons.straighten,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Text(route.distance,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(width: 10),
                Icon(Icons.schedule,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Text(route.duration,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
            const SizedBox(height: 12),

            // Station-wise AQI
            if (route.waypoints.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Station-wise Air Quality',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...route.waypoints.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final wp = entry.value;
                      final isFirst = idx == 0;
                      final isLast =
                          idx == route.waypoints.length - 1;
                      final name = (wp.townName.isNotEmpty &&
                              !wp.townName.startsWith('Point'))
                          ? wp.townName
                          : 'Waypoint ${idx + 1}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? const Color(0xFF4CAF50)
                                    : isLast
                                        ? const Color(0xFFF44336)
                                        : Color(wp.colorHex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isFirst)
                              const Text('🟢 ',
                                  style: TextStyle(fontSize: 10))
                            else if (isLast)
                              const Text('🔴 ',
                                  style: TextStyle(fontSize: 10)),
                            Expanded(
                              child: Text(name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: (isFirst || isLast)
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: Colors.grey.shade800),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    Color(wp.colorHex).withAlpha(20),
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                    color: Color(wp.colorHex)
                                        .withAlpha(60)),
                              ),
                              child: Text('AQI ${wp.aqi}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(wp.colorHex))),
                            ),
                            const SizedBox(width: 6),
                            Text(
                                'PM2.5: ${wp.pm25.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            if (route.waypoints.isNotEmpty) const SizedBox(height: 8),

            // Reason
            Text(route.reason.split('\n').first,
                style: TextStyle(
                    fontSize: 11,
                    color: isBest
                        ? Colors.green.shade600
                        : Colors.red.shade600)),
            const SizedBox(height: 10),

            // View on Map
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onSelect,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: Text('View on Map',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isBest ? Colors.green : AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CITY AUTOCOMPLETE ====================
class _CityAutocompleteField extends StatelessWidget {
  final String initialValue;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<String> onTextChanged;
  final VoidCallback? onSubmitted;

  const _CityAutocompleteField({
    required this.initialValue,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.onTextChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue textEditingValue) {
        onTextChanged(textEditingValue.text);
        if (textEditingValue.text.length < 2) {
          return const Iterable<String>.empty();
        }
        final q = textEditingValue.text.toLowerCase();
        final starts = RouteProvider.indianCities
            .where((c) => c.toLowerCase().startsWith(q))
            .toList();
        final contains = RouteProvider.indianCities
            .where((c) =>
                !c.toLowerCase().startsWith(q) &&
                c.toLowerCase().contains(q))
            .toList();
        return [...starts, ...contains].take(6);
      },
      optionsViewBuilder: (BuildContext ctx,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints:
                  const BoxConstraints(maxHeight: 250, maxWidth: 350),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final city = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(city),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.shade100))),
                      child: Row(
                        children: [
                          Icon(Icons.location_city,
                              size: 16, color: iconColor),
                          const SizedBox(width: 10),
                          Text(city,
                              style: GoogleFonts.poppins(fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (BuildContext ctx,
          TextEditingController textController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: iconColor, width: 2)),
          ),
          textInputAction: onSubmitted != null
              ? TextInputAction.search
              : TextInputAction.next,
          onSubmitted: (_) {
            if (onSubmitted != null) onSubmitted!();
          },
        );
      },
      onSelected: (String selection) {
        onTextChanged(selection);
      },
    );
  }
}

// ==================== PAGE 3: FULL SCREEN MAP ====================
class _FullMapPage extends StatefulWidget {
  final FreeRouteModel route;
  final String travelMode;
  final String origin;
  final String destination;
  final VoidCallback onBack;

  const _FullMapPage({
    required this.route,
    required this.travelMode,
    required this.origin,
    required this.destination,
    required this.onBack,
  });

  @override
  State<_FullMapPage> createState() => _FullMapPageState();
}

class _FullMapPageState extends State<_FullMapPage> {
  final _mapCtrl = MapController();
  bool _isNav = false;
  LatLng? _curLoc;
  int _curAqi = 0;
  int _curColor = 0xFF4CAF50;
  StreamSubscription<Position>? _posSub;
  Timer? _aqiTimer;
  List<LatLng> _path = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
  }

  @override
  void dispose() {
    _stopNav();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _isNav ? _buildNavTopBar() : _buildTopBar()),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _isNav ? _buildNavBottomBar() : _buildBottomBar()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final polylines = <Polyline>[
      Polyline(
          points: widget.route.routePoints,
          color: Color(widget.route.routeColorHex),
          strokeWidth: 6),
    ];
    if (_path.length > 1) {
      polylines
          .add(Polyline(points: _path, color: Colors.blue, strokeWidth: 5));
    }

    final markers = <Marker>[];
    for (final wp in widget.route.waypoints) {
      markers.add(Marker(
        point: wp.position,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
              color: Color(wp.colorHex),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2)),
          child: Center(
              child: Text('${wp.aqi}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white))),
        ),
      ));
    }
    if (widget.route.routePoints.isNotEmpty) {
      markers.add(Marker(
          point: widget.route.routePoints.first,
          width: 44,
          height: 44,
          child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50), shape: BoxShape.circle),
              child: const Icon(Icons.my_location,
                  color: Colors.white, size: 18))));
      markers.add(Marker(
          point: widget.route.routePoints.last,
          width: 44,
          height: 44,
          child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Color(0xFFF44336), shape: BoxShape.circle),
              child: const Icon(Icons.flag,
                  color: Colors.white, size: 18))));
    }
    if (_curLoc != null && _isNav) {
      markers.add(Marker(
          point: _curLoc!,
          width: 50,
          height: 50,
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3)),
              child: const Icon(Icons.navigation,
                  color: Colors.white, size: 18))));
    }

    return FlutterMap(
      mapController: _mapCtrl,
      options:
          const MapOptions(initialCenter: LatLng(15.0, 78.0), initialZoom: 8),
      children: [
        TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.air_quality_app',
            maxZoom: 19),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 10),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack),
              const Icon(Icons.my_location, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Expanded(
                  child: Text('${widget.origin} → ${widget.destination}',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Color(widget.route.aqiColorHex).withAlpha(20),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('AQI ${widget.route.averageAqi}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(widget.route.aqiColorHex))),
              ),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildBottomBar() {
    final r = widget.route;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: Color(r.routeColorHex),
                        shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(r.summary,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoChip(Icons.straighten, r.distance, Colors.blue),
                _infoChip(Icons.schedule, r.duration, Colors.purple),
                _infoChip(
                    Icons.air, 'AQI ${r.averageAqi}', Color(r.aqiColorHex)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _startNav,
                icon: Icon(_modeIcon(), size: 20),
                label: Text('Start ${_modeLabel()} Navigation',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withAlpha(12), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildNavTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(_curColor), Color(_curColor).withAlpha(180)]),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: _stopNav,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(10)),
                  child:
                      const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Icon(_modeIcon(), color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Navigating...',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('AQI $_curAqi',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _stopNav,
            icon: const Icon(Icons.stop_circle, size: 20),
            label: const Text('Stop Navigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  IconData _modeIcon() {
    switch (widget.travelMode) {
      case 'cycling':
        return Icons.directions_bike;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.directions_car;
    }
  }

  String _modeLabel() {
    switch (widget.travelMode) {
      case 'cycling':
        return 'Bike';
      case 'walking':
        return 'Walk';
      default:
        return 'Car';
    }
  }

  void _fitRoute() {
    if (widget.route.routePoints.isEmpty) return;
    double minLat = widget.route.routePoints.first.latitude;
    double maxLat = minLat;
    double minLng = widget.route.routePoints.first.longitude;
    double maxLng = minLng;
    for (final p in widget.route.routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final latPad = (maxLat - minLat) * 0.1;
    final lngPad = (maxLng - minLng) * 0.1;
    _mapCtrl.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(minLat - latPad, minLng - lngPad),
        LatLng(maxLat + latPad, maxLng + lngPad),
      ),
      padding: const EdgeInsets.fromLTRB(30, 80, 30, 160),
    ));
  }

  Future<void> _startNav() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _isNav = true;
        _curLoc = LatLng(pos.latitude, pos.longitude);
        _path = [_curLoc!];
      });
      _mapCtrl.move(_curLoc!, 15);
      await _updateAqi();

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((pos) {
        if (!mounted) return;
        setState(() {
          _curLoc = LatLng(pos.latitude, pos.longitude);
          _path.add(_curLoc!);
        });
        _mapCtrl.move(_curLoc!, _mapCtrl.camera.zoom);
      });

      _aqiTimer =
          Timer.periodic(const Duration(seconds: 30), (_) => _updateAqi());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _stopNav() {
    _posSub?.cancel();
    _aqiTimer?.cancel();
    if (mounted) {
      setState(() {
        _isNav = false;
        _path = [];
        _curLoc = null;
      });
    }
  }

  Future<void> _updateAqi() async {
    if (_curLoc == null) return;
    try {
      final res = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/air_pollution'
        '?lat=${_curLoc!.latitude}&lon=${_curLoc!.longitude}'
        '&appid=${ApiKeys.openWeatherMapKey}',
      ));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        final owm = d['list'][0]['main']['aqi'] as int;
        final std = [25, 75, 125, 175, 300][owm.clamp(1, 5) - 1];
        if (mounted) {
          setState(() {
            _curAqi = std;
            _curColor = std <= 50
                ? 0xFF4CAF50
                : std <= 100
                    ? 0xFFFFEB3B
                    : std <= 150
                        ? 0xFFFF9800
                        : 0xFFF44336;
          });
        }
      }
    } catch (_) {}
  }

  int _pm25ToIndianAqi(double pm25) {
    if (pm25 <= 0) return 0;
    if (pm25 <= 30.0) return (50.0 * pm25 / 30.0).round();
    if (pm25 <= 60.0) return (51 + (49.0 * (pm25 - 30.0) / 30.0)).round();
    if (pm25 <= 90.0) return (101 + (99.0 * (pm25 - 60.0) / 30.0)).round();
    if (pm25 <= 120.0) return (201 + (99.0 * (pm25 - 90.0) / 30.0)).round();
    if (pm25 <= 250.0) return (301 + (99.0 * (pm25 - 120.0) / 130.0)).round();
    return (401 + (99.0 * (pm25 - 250.0) / 130.0)).round().clamp(401, 500);
  }
}