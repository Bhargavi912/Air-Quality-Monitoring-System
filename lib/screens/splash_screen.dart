import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showButton = true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _goToHome() {
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => const HomeScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.greenGradient,
                    boxShadow: [BoxShadow(color: AppTheme.accentCyan.withAlpha(50), blurRadius: 40, spreadRadius: 8)],
                  ),
                  child: const Icon(Icons.air_rounded, size: 55, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(children: [
                  Text('AIR QUALITY', style: GoogleFonts.rajdhani(
                      fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 6)),
                  Text('MONITORING SYSTEM', style: GoogleFonts.rajdhani(
                      fontSize: 16, fontWeight: FontWeight.w400, color: AppTheme.accentCyan, letterSpacing: 8)),
                  const SizedBox(height: 16),
                  Text('Breathe Smart. Live Healthy.', style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white54, fontStyle: FontStyle.italic)),
                ]),
              ),
              const Spacer(flex: 2),

              // GET STARTED button
              AnimatedOpacity(
                opacity: _showButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: _showButton ? _goToHome : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: AppTheme.primaryDark,
                        elevation: 8,
                        shadowColor: AppTheme.accentCyan.withAlpha(80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Get Started', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, size: 22),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}