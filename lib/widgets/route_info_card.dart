import 'package:flutter/material.dart';
import '../models/free_route_model.dart';

class RouteInfoCard extends StatelessWidget {
  final FreeRouteModel route;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onInfoTap;

  const RouteInfoCard({
    super.key,
    required this.route,
    required this.isSelected,
    required this.onTap,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 230,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Color(route.routeColorHex) : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Color(route.routeColorHex).withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Row 1: Route name + Badge
              Row(children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Color(route.routeColorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    route.summary,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (route.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🏆 BEST',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text('❌ #${route.rank}',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.red.shade400)),
                  ),
              ]),

              // Row 2: AQI
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(route.aqiColorHex).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(route.aqiColorHex).withAlpha(60)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(route.aqiEmoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('AQI ${route.averageAqi}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(route.aqiColorHex))),
                    Text(route.aqiLevel,
                        style: TextStyle(fontSize: 8, color: Color(route.aqiColorHex))),
                  ]),
                ]),
              ),

              // Row 3: Reason (short — first line only)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: route.isRecommended
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      route.reason.split('\n').first,
                      style: TextStyle(
                        fontSize: 8,
                        color: route.isRecommended ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onInfoTap != null)
                    GestureDetector(
                      onTap: onInfoTap,
                      child: Icon(Icons.info_outline, size: 14,
                          color: route.isRecommended ? Colors.green : Colors.red),
                    ),
                ]),
              ),

              // Row 4: Distance & Duration
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(Icons.straighten, size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(route.distance, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ]),
                Row(children: [
                  Icon(Icons.schedule, size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(route.duration, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ]),
              ]),

              // Row 5: AQI color bar
              if (route.waypoints.isNotEmpty)
                Row(children: [
                  Text('AQI: ', style: TextStyle(fontSize: 7, color: Colors.grey.shade500)),
                  Expanded(child: Row(children: route.waypoints.map((wp) {
                    return Expanded(child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: Color(wp.colorHex), borderRadius: BorderRadius.circular(2))));
                  }).toList())),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}