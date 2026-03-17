import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/air_quality_provider.dart';
import 'models/user_profile_model.dart';
import 'screens/home_screen.dart';
import 'screens/user_registration_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AirQualityProvider(),
      child: MaterialApp(
        title: 'BreathSafe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: const SplashRouter(),
      ),
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final exists = await UserProfile.exists();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => exists ? const HomeScreen() : const UserRegistrationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🌿', style: TextStyle(fontSize: 60)),
              SizedBox(height: 16),
              Text('BreathSafe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 8),
              Text('Air Quality Monitoring System', style: TextStyle(fontSize: 14, color: Colors.white54)),
              SizedBox(height: 30),
              CircularProgressIndicator(color: Color(0xFF26DE81), strokeWidth: 3),
            ],
          ),
        ),
      ),
    );
  }
}