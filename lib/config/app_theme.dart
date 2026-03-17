import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ===== BRAND COLORS =====
  static const Color primaryDark = Color(0xFF1B1F3B);
  static const Color primaryBlue = Color(0xFF3D5AFE);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF8E8E93);

  // ===== AQI COLORS =====
  static const Color aqiGood = Color(0xFF4CAF50);
  static const Color aqiFair = Color(0xFFFFC107);
  static const Color aqiModerate = Color(0xFFFF9800);
  static const Color aqiPoor = Color(0xFFF44336);
  static const Color aqiVeryPoor = Color(0xFF9C27B0);
  static const Color aqiHazardous = Color(0xFF880E4F);

  // ===== GRADIENTS =====
  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFf12711), Color(0xFFf5af19)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== THEME =====
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      textTheme: GoogleFonts.poppinsTextTheme(),
      colorSchemeSeed: primaryBlue,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ===== AQI HELPERS =====
  static Color getAqiColor(int aqi) {
    if (aqi <= 50) return aqiGood;
    if (aqi <= 100) return aqiFair;
    if (aqi <= 150) return aqiModerate;
    if (aqi <= 200) return aqiPoor;
    if (aqi <= 300) return aqiVeryPoor;
    return aqiHazardous;
  }

  static LinearGradient getAqiGradient(int aqi) {
    if (aqi <= 50) return greenGradient;
    if (aqi <= 100) return const LinearGradient(colors: [Color(0xFFF7971E), Color(0xFFFFD200)]);
    if (aqi <= 150) return orangeGradient;
    if (aqi <= 200) return const LinearGradient(colors: [Color(0xFFEB3349), Color(0xFFF45C43)]);
    return const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]);
  }

  static String getAqiEmoji(int aqi) {
    if (aqi <= 50) return '😊';
    if (aqi <= 100) return '🙂';
    if (aqi <= 150) return '😐';
    if (aqi <= 200) return '😷';
    if (aqi <= 300) return '🤢';
    return '☠️';
  }
}