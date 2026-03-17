import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile_model.dart';
import '../providers/air_quality_provider.dart';

import 'dashboard_screen.dart';
import 'forecast_screen.dart';
import 'health_advisory_screen.dart';
import 'route_planner_screen.dart';
import 'symptom_tracker_screen.dart';
import 'user_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AirQualityProvider>().startLiveMode();
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardAnimations = List.generate(5, (i) {
      return CurvedAnimation(
        parent: _animController,
        curve: Interval(i * 0.08, (i * 0.08 + 0.55).clamp(0.0, 1.0), curve: Curves.easeOutBack),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Added context-aware emojis to the greeting
  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 🌅';
    if (h < 17) return 'Good Afternoon ☀️';
    if (h < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  String _getEmoji(int aqi) {
    if (aqi <= 50) return '😊';
    if (aqi <= 100) return '🙂';
    if (aqi <= 200) return '😐';
    if (aqi <= 300) return '😷';
    if (aqi <= 400) return '🤢';
    return '☠️';
  }

  Color _aqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00C853); 
    if (aqi <= 100) return const Color(0xFFFFD600); 
    if (aqi <= 200) return const Color(0xFFFF6D00); 
    if (aqi <= 300) return const Color(0xFFFF1744); 
    if (aqi <= 400) return const Color(0xFFD500F9); 
    return const Color(0xFFB71C1C); 
  }

  Color _getTextColorForAqi(int aqi) {
    if (aqi <= 100) return const Color(0xFF1E293B);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  FutureBuilder<UserProfile?>(
                    future: UserProfile.load(),
                    builder: (context, snap) {
                      final name = snap.data?.name ?? '';
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8), 
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name.isEmpty ? 'BreathSafe' : name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final profile = await UserProfile.load();
                              if (!context.mounted) return;
                              final ok = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserRegistrationScreen(
                                    isEditing: true,
                                    existingProfile: profile,
                                  ),
                                ),
                              );
                              if (ok == true && mounted) setState(() {});
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], 
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF6366F1),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  )
                                ]
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '👤',
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // AQI hero
                  Consumer<AirQualityProvider>(
                    builder: (context, provider, _) {
                      final a = provider.currentAqi;
                      if (a == null) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: const Color(0xFF1E293B),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text('Detecting air quality...',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }
                      final v = a.standardAqi;
                      final color = _aqiColor(v);
                      final textColor = _getTextColorForAqi(v);
                      
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: const Color(0xFF1E293B), 
                          border: Border.all(color: color, width: 2), 
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ]
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color, 
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$v',
                                      style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: textColor,
                                          height: 1)),
                                  Text('AQI',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: textColor,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(_getEmoji(v), style: const TextStyle(fontSize: 20)),
                                      const SizedBox(width: 8),
                                      Text(a.level,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: color)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (provider.locationName != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded,
                                            size: 16, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            provider.locationName!,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFFE2E8F0)), 
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _miniChip('PM2.5', a.pm25.toStringAsFixed(0), color, textColor),
                                      _miniChip('PM10', a.pm10.toStringAsFixed(0), color, textColor),
                                      _miniChip('O₃', a.o3.toStringAsFixed(0), color, textColor),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- NEW: Live Auto-updating Status ---
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853), // Live green dot
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live • Auto-updating',
                        style: TextStyle(
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Just now',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.refresh_rounded, 
                        color: Color(0xFF64748B), 
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Modules title
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: 10),
                      const Text('Explore Modules',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- MODULE CARDS GRID ---
                  LayoutBuilder(builder: (context, c) {
                    final w = c.maxWidth;
                    final cols = w > 850 ? 3 : 2;
                    final spacing = 16.0;
                    
                    final cardW = ((w - spacing * (cols - 1)) / cols) - 0.1;
                    final cardH = cols == 3 ? cardW * 0.95 : cardW * 1.25;

                    final modules = [
                      _ModuleData(Icons.dashboard_rounded, 'Dashboard', 'Real-time AQI\n& Pollutants',
                          [const Color(0xFFF43F5E), const Color(0xFFE11D48)], 
                          () => _navigateTo(const DashboardScreen())),
                      _ModuleData(Icons.health_and_safety_rounded, 'Health', 'Personalized\nAdvisory',
                          [const Color(0xFF10B981), const Color(0xFF059669)], 
                          () => _navigateTo(const HealthAdvisoryScreen())),
                      _ModuleData(Icons.route_rounded, 'Routes', 'Clean Air\nRoute Planner',
                          [const Color(0xFF3B82F6), const Color(0xFF2563EB)], 
                          () => _navigateTo(const RoutePlannerScreen())),
                      _ModuleData(Icons.show_chart_rounded, 'Forecast', 'AQI Prediction\n& Trends',
                          [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], 
                          () => _navigateTo(const ForecastScreen())),
                      _ModuleData(Icons.monitor_heart_rounded, 'Symptoms',
                          'Track Health\n& AQI Patterns',
                          [const Color(0xFFF59E0B), const Color(0xFFD97706)], 
                          () => _navigateTo(const SymptomTrackerScreen())),
                    ];

                    List<Widget> cards = [];
                    for (int i = 0; i < modules.length; i++) {
                      cards.add(
                        SizedBox(
                          width: cardW,
                          height: cardH,
                          child: ScaleTransition(
                            scale: _cardAnimations[i],
                            child: _buildCard(modules[i]),
                          ),
                        )
                      );
                    }
                    
                    return SizedBox(
                      width: double.infinity, 
                      child: Wrap(
                        alignment: WrapAlignment.center, 
                        spacing: spacing,
                        runSpacing: spacing,
                        children: cards,
                      ),
                    );
                  }),
                  const SizedBox(height: 28),

                  // Quick guide card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF1E293B), 
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFF38BDF8)), 
                              child: const Center(
                                  child: Text('💡', style: TextStyle(fontSize: 16))),
                            ),
                            const SizedBox(width: 12),
                            const Text('Quick Guide',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _tipRow('1', 'Dashboard for live AQI data'),
                        _tipRow('2', 'Health for personalized advice'),
                        _tipRow('3', 'Routes for cleanest air path'),
                        _tipRow('4', 'Forecast to plan your day'),
                        _tipRow('5', 'Symptoms to track health patterns'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('BreathSafe v1.0 • Built with Flutter',
                        style: TextStyle(
                            color: Color(0xFF64748B), 
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, 
          borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              fontSize: 11, 
              color: textColor, 
              fontWeight: FontWeight.w800)),
    );
  }

  Widget _tipRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFF334155)), 
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)))), 
        ],
      ),
    );
  }

  Widget _buildCard(_ModuleData m) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: m.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: m.colors, 
            ),
            boxShadow: [
              BoxShadow(
                color: m.colors[1].withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24, 
                ),
                child: Icon(m.icon, color: Colors.white, size: 30),
              ),
              const Spacer(),
              Text(
                m.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                m.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white, 
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        color: m.colors[1], 
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: m.colors[1], size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  _ModuleData(this.icon, this.title, this.subtitle, this.colors, this.onTap);
}