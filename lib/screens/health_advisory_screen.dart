import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';

// ============================================================================
// 1. SELECTION SCREEN (Choose Location or Search City)
// ============================================================================
class HealthAdvisoryScreen extends StatelessWidget {
  const HealthAdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('👤 Health Advisory', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How would you like to check the air quality?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Get personalized health advice based on your location and medical conditions.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Current Location Option
            _buildOptionCard(
              context: context,
              title: 'Current Location',
              subtitle: 'Use your live GPS data',
              icon: Icons.my_location,
              color: Colors.blue,
              isCitySearch: false,
            ),
            const SizedBox(height: 20),
            
            // Search City Option
            _buildOptionCard(
              context: context,
              title: 'Search City',
              subtitle: 'Check air quality anywhere',
              icon: Icons.location_city,
              color: Colors.orange,
              isCitySearch: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isCitySearch,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdvisoryFlowScreen(isCitySearch: isCitySearch),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. ADVISORY FLOW WIZARD (Age, Symptoms, Results)
// ============================================================================
class AdvisoryFlowScreen extends StatefulWidget {
  final bool isCitySearch;
  const AdvisoryFlowScreen({super.key, required this.isCitySearch});

  @override
  State<AdvisoryFlowScreen> createState() => _AdvisoryFlowScreenState();
}

class _AdvisoryFlowScreenState extends State<AdvisoryFlowScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _otherSymptomController = TextEditingController(); 
  
  String _typedCityInput = '';
  Map<String, dynamic>? _selectedCityData; // Holds lat/lon if user clicks autocomplete suggestion
  
  Map<String, dynamic>? _advice;
  int _currentStep = 1;
  bool _isLoading = false; 

  final List<Map<String, dynamic>> _symptomOptions = [
    {'key': 'none', 'label': 'None (No health issues)', 'icon': Icons.check_circle, 'color': Colors.green},
    {'key': 'asthma', 'label': 'Asthma', 'icon': Icons.air, 'color': Colors.red},
    {'key': 'sinusitis', 'label': 'Sinusitis / Sinus Problems', 'icon': Icons.face, 'color': Colors.orange},
    {'key': 'cold', 'label': 'Cold / Flu', 'icon': Icons.sick, 'color': Colors.blue},
    {'key': 'cough', 'label': 'Chronic Cough', 'icon': Icons.record_voice_over, 'color': Colors.amber},
    {'key': 'allergy', 'label': 'Allergies (Dust/Pollen)', 'icon': Icons.grass, 'color': Colors.lime},
    {'key': 'bronchitis', 'label': 'Bronchitis', 'icon': Icons.healing, 'color': Colors.deepOrange},
    {'key': 'copd', 'label': 'COPD', 'icon': Icons.monitor_heart, 'color': Colors.purple},
    {'key': 'heart', 'label': 'Heart Disease', 'icon': Icons.favorite, 'color': Colors.red},
    {'key': 'eye_irritation', 'label': 'Eye Irritation', 'icon': Icons.remove_red_eye, 'color': Colors.teal},
    {'key': 'throat', 'label': 'Throat Irritation', 'icon': Icons.mic, 'color': Colors.brown},
    {'key': 'headache', 'label': 'Frequent Headaches', 'icon': Icons.psychology, 'color': Colors.indigo},
    {'key': 'breathing', 'label': 'Breathing Difficulty', 'icon': Icons.airline_seat_flat, 'color': Colors.redAccent},
    {'key': 'skin', 'label': 'Skin Allergy / Rashes', 'icon': Icons.back_hand, 'color': Colors.pink},
    {'key': 'other', 'label': 'Other (Specify)', 'icon': Icons.add_circle, 'color': Colors.blueGrey},
  ];

  final Set<String> _selectedSymptoms = {'none'};

  void _onSymptomToggle(String key) {
    setState(() {
      if (key == 'none') {
        _selectedSymptoms.clear();
        _selectedSymptoms.add('none');
        _otherSymptomController.clear();
      } else {
        _selectedSymptoms.remove('none');
        if (_selectedSymptoms.contains(key)) {
          _selectedSymptoms.remove(key);
          if (key == 'other') _otherSymptomController.clear();
          if (_selectedSymptoms.isEmpty) _selectedSymptoms.add('none');
        } else {
          _selectedSymptoms.add(key);
        }
      }
    });
  }

  void _nextStep() {
    if (widget.isCitySearch) {
      if (_typedCityInput.trim().isEmpty && _selectedCityData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please search and select a city'), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age <= 0 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age (1-120)'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _currentStep = 2);
  }

  void _backStep() {
    setState(() {
      if (_currentStep > 1) _currentStep--;
    });
  }

  void _reset() {
    setState(() {
      _currentStep = 1;
      _ageController.clear();
      _otherSymptomController.clear();
      _selectedSymptoms.clear();
      _selectedSymptoms.add('none');
      _typedCityInput = '';
      _selectedCityData = null;
      _advice = null;
    });
  }

  // --- AUTOCOMPLETE API CALL ---
  Future<Iterable<Map<String, dynamic>>> _getCitySuggestions(String query) async {
    if (query.length < 2) return const Iterable.empty();
    try {
      final url = 'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=5';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['results'] != null) {
          return (data['results'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return const Iterable.empty();
  }

  // --- LIVE GEOCODING AND AQI FETCHING ---
  Future<Map<String, dynamic>?> _fetchCityAqi() async {
    try {
      double lat;
      double lon;
      String locationName;

      // If user selected from dropdown, we already have exact GPS coordinates
      if (_selectedCityData != null) {
        lat = _selectedCityData!['latitude'];
        lon = _selectedCityData!['longitude'];
        final admin1 = _selectedCityData!['admin1'] ?? '';
        final country = _selectedCityData!['country'] ?? '';
        locationName = [_selectedCityData!['name'], admin1, country].where((s) => s.isNotEmpty).join(', ');
      } else {
        // If user just typed text and didn't select dropdown, fetch geocoding
        final geoRes = await http.get(Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(_typedCityInput)}&count=1'));
        if (geoRes.statusCode != 200) return null;
        final geoData = jsonDecode(geoRes.body);
        if (geoData['results'] == null || geoData['results'].isEmpty) return null;
        
        lat = geoData['results'][0]['latitude'];
        lon = geoData['results'][0]['longitude'];
        final cName = geoData['results'][0]['name'];
        final cAdmin = geoData['results'][0]['admin1'] ?? '';
        locationName = [cName, cAdmin].where((s) => s.isNotEmpty).join(', ');
      }

      // Air Quality API to get PM2.5
      final aqiRes = await http.get(Uri.parse('https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&current=pm2_5'));
      if (aqiRes.statusCode != 200) return null;
      
      final aqiData = jsonDecode(aqiRes.body);
      final pm25 = (aqiData['current']['pm2_5'] ?? 0.0).toDouble();
      
      // Convert PM2.5 to US AQI
      int aqi = _calculateUsAqi(pm25);

      return {
        'aqi': aqi,
        'pm25': pm25,
        'name': locationName,
      };
    } catch (e) {
      return null;
    }
  }

  // Standard EPA formula to convert PM2.5 concentration to AQI
  int _calculateUsAqi(double pm25) {
    if (pm25 <= 12.0) return ((50 - 0) / (12.0 - 0.0) * (pm25 - 0.0) + 0).round();
    if (pm25 <= 35.4) return ((100 - 51) / (35.4 - 12.1) * (pm25 - 12.1) + 51).round();
    if (pm25 <= 55.4) return ((150 - 101) / (55.4 - 35.5) * (pm25 - 35.5) + 101).round();
    if (pm25 <= 150.4) return ((200 - 151) / (150.4 - 55.5) * (pm25 - 55.5) + 151).round();
    if (pm25 <= 250.4) return ((300 - 201) / (250.4 - 150.5) * (pm25 - 150.5) + 201).round();
    if (pm25 <= 350.4) return ((400 - 301) / (350.4 - 250.5) * (pm25 - 250.5) + 301).round();
    return ((500 - 401) / (500.4 - 350.5) * (pm25 - 350.5) + 401).round();
  }

  Future<void> _getAdvice() async {
    final age = int.tryParse(_ageController.text);
    if (age == null || age <= 0 || age > 120) return;
    
    if (_selectedSymptoms.contains('other') && _otherSymptomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type your condition in the "Other" text box'), backgroundColor: Colors.orange),
      );
      return;
    }

    final conditions = _selectedSymptoms.where((s) => s != 'none').toList();
    int fetchedAqi = 0;
    double fetchedPm25 = 0.0;
    String locationLabel = '';

    if (widget.isCitySearch) {
      setState(() => _isLoading = true);
      
      final cityData = await _fetchCityAqi();
      
      if (cityData == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find city or air quality data. Please check the spelling.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      fetchedAqi = cityData['aqi'];
      fetchedPm25 = cityData['pm25'];
      locationLabel = cityData['name'];
      
      setState(() => _isLoading = false);
    } else {
      final provider = context.read<AirQualityProvider>();
      if (provider.currentAqi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AQI data not loaded. Go to Home tab first.'), backgroundColor: Colors.orange),
        );
        return;
      }
      fetchedAqi = provider.currentAqi!.standardAqi;
      fetchedPm25 = provider.currentAqi!.pm25;
      locationLabel = provider.locationName ?? 'Current Location';
    }

    setState(() {
      _advice = _generateAdvice(
        age: age, 
        aqi: fetchedAqi, 
        conditions: conditions, 
        pm25: fetchedPm25,
        locationName: locationLabel,
      );
      _currentStep = 3;
    });
  }

  // --- LOGIC AND UI BUILDERS BELOW ---

  String _ageGroup(int age) {
    if (age <= 5) return 'toddler';
    if (age <= 12) return 'child';
    if (age <= 17) return 'teen';
    if (age <= 45) return 'adult';
    if (age <= 60) return 'middle';
    if (age <= 75) return 'senior';
    return 'elderly';
  }

  Map<String, dynamic> _generateAdvice({
    required int age,
    required int aqi,
    required List<String> conditions,
    required double pm25,
    required String locationName,
  }) {
    final ageGrp = _ageGroup(age);

    bool hasRespiratory = conditions.any((c) => ['asthma', 'bronchitis', 'copd', 'breathing'].contains(c));
    bool hasHeart = conditions.contains('heart');
    bool hasAllergy = conditions.any((c) => ['allergy', 'sinusitis', 'eye_irritation', 'skin'].contains(c));
    bool hasMild = conditions.any((c) => ['cold', 'cough', 'throat', 'headache'].contains(c));
    bool hasOther = conditions.contains('other');

    String customCond = '';
    if (hasOther) {
      customCond = _otherSymptomController.text.trim();
      if (customCond.isEmpty) customCond = 'your specific condition';
    }

    double riskMultiplier = 1.0;
    if (['toddler', 'child', 'senior', 'elderly'].contains(ageGrp)) riskMultiplier += 0.5;
    if (ageGrp == 'toddler' || ageGrp == 'elderly') riskMultiplier += 0.3;
    if (hasRespiratory) riskMultiplier += 1.0;
    if (hasHeart) riskMultiplier += 0.8;
    if (hasAllergy) riskMultiplier += 0.5;
    if (hasMild) riskMultiplier += 0.3;
    if (hasOther) riskMultiplier += 0.4;

    String level;
    String emoji;
    int colorValue;
    bool canGoOutside;
    String message;
    List<String> recommendations = [];
    List<String> precautions = [];

    bool primaryIsOther = (!hasRespiratory && !hasHeart && !hasAllergy && !hasMild && hasOther);

    if (aqi <= 50) {
      if (hasRespiratory) {
        level = 'Good — Carry Medication';
        emoji = '⚠️';
        colorValue = 0xFFC6CC00;
        canGoOutside = true;
        message = 'Air is clean but always be prepared with your condition.';
        recommendations = _getRespiratoryGoodRec(ageGrp);
        precautions = _getRespiratoryGoodPrec(ageGrp);
      } else if (hasHeart) {
        level = 'Good — Light Activity OK';
        emoji = '✅';
        colorValue = 0xFF4CAF50;
        canGoOutside = true;
        message = 'Air quality is great. Light outdoor activities are safe.';
        recommendations = ['✅ Light walking in parks is safe', '💊 Carry heart medication as always', '💧 Stay hydrated — drink water every 30 min', '🩺 Monitor heart rate during activity'];
        precautions = ['Avoid sudden intense exercise', 'Rest immediately if you feel chest discomfort', 'Stay in shaded areas to avoid heat stress'];
      } else if (hasAllergy) {
        level = 'Good — Watch for Triggers';
        emoji = '✅';
        colorValue = 0xFF4CAF50;
        canGoOutside = true;
        message = 'Air quality is good but pollen/dust may still cause issues.';
        recommendations = _getAllergyGoodRec(ageGrp);
        precautions = _getAllergyGoodPrec(ageGrp);
      } else if (hasMild) {
        level = 'Good — Rest Recommended';
        emoji = '✅';
        colorValue = 0xFF4CAF50;
        canGoOutside = true;
        message = 'Air is clean. Focus on recovering from your cold/cough.';
        recommendations = _getMildGoodRec(ageGrp);
        precautions = _getMildGoodPrec(ageGrp);
      } else if (hasOther) {
        level = 'Good — Monitor Symptoms';
        emoji = '✅';
        colorValue = 0xFF4CAF50;
        canGoOutside = true;
        message = 'Air is clean, but stay mindful of your specific health condition.';
        recommendations = ['✅ Outdoor activities are generally safe today', '💊 Carry any medications needed for $customCond', '💧 Stay hydrated throughout the day'];
        precautions = ['Watch for any unusual flare-ups related to $customCond', 'Consult your doctor if you feel unwell'];
      } else {
        level = 'Good';
        emoji = '✅';
        colorValue = 0xFF4CAF50;
        canGoOutside = true;
        message = 'Air quality is excellent! Enjoy your day.';
        recommendations = _getHealthyGoodRec(ageGrp);
        precautions = [];
      }
    } else if (aqi <= 100) {
      if (hasRespiratory) {
        level = 'Moderate Risk for You';
        emoji = '🟠';
        colorValue = 0xFFFF9800;
        canGoOutside = false;
        message = 'Air may trigger your respiratory condition. Stay cautious.';
        recommendations = _getRespiratorySatRec(ageGrp);
        precautions = _getRespiratorySatPrec(ageGrp);
      } else if (hasHeart) {
        level = 'Satisfactory — Limit Exertion';
        emoji = '🟡';
        colorValue = 0xFFC6CC00;
        canGoOutside = true;
        message = 'Air is acceptable but avoid heavy physical work.';
        recommendations = ['⚠️ Limit outdoor activity to 30 minutes', '🚶 Slow walking only — no jogging', '💊 Take morning medication on time', '💧 Drink warm water regularly', '🏠 Prefer indoor exercise (yoga, stretching)'];
        precautions = ['Avoid walking near busy roads', 'Monitor blood pressure before and after outing', 'Stop activity immediately if you feel dizzy or chest pain', 'Avoid going out during peak traffic hours (8-10 AM)'];
      } else if (hasAllergy) {
        level = 'Satisfactory — Allergy Alert';
        emoji = '🟡';
        colorValue = 0xFFC6CC00;
        canGoOutside = true;
        message = 'Air is okay but allergens may be present.';
        recommendations = _getAllergySatRec(ageGrp);
        precautions = _getAllergySatPrec(ageGrp);
      } else if (hasMild) {
        level = 'Satisfactory — Take Care';
        emoji = '🟡';
        colorValue = 0xFFC6CC00;
        canGoOutside = true;
        message = 'Air is acceptable. Your cold/cough may feel slightly worse.';
        recommendations = _getMildSatRec(ageGrp);
        precautions = _getMildSatPrec(ageGrp);
      } else if (hasOther) {
        level = 'Satisfactory — Take Precautions';
        emoji = '🟡';
        colorValue = 0xFFC6CC00;
        canGoOutside = true;
        message = 'Air is acceptable, but monitor your custom condition for any triggers.';
        recommendations = ['⚠️ Limit strenuous outdoor activities', '💊 Ensure you have medications for $customCond', '🏠 Take breaks indoors if you feel fatigued'];
        precautions = ['If $customCond makes you sensitive to dust, wear a mask', 'Reduce outdoor time if symptoms appear'];
      } else {
        level = 'Satisfactory';
        emoji = '🟡';
        colorValue = 0xFFC6CC00;
        canGoOutside = true;
        message = 'Air is acceptable for most people.';
        recommendations = _getHealthySatRec(ageGrp);
        precautions = _getHealthySatPrec(ageGrp);
      }
    } else if (aqi <= 200) {
      if (hasRespiratory) {
        level = 'DANGEROUS for You!';
        emoji = '🚨';
        colorValue = 0xFFD32F2F;
        canGoOutside = false;
        message = 'VERY HIGH RISK! Your lungs cannot handle this air.';
        recommendations = _getRespiratoryModRec(ageGrp);
        precautions = _getRespiratoryModPrec(ageGrp);
      } else if (hasHeart) {
        level = 'High Risk — Stay Indoors';
        emoji = '🔴';
        colorValue = 0xFFF44336;
        canGoOutside = false;
        message = 'Pollution can trigger heart complications. Avoid outdoor exposure.';
        recommendations = ['🚫 Cancel all outdoor plans', '🏠 Stay in air-conditioned room', '💊 Take heart medication as prescribed', '🩺 Check blood pressure every 3 hours', '💧 Drink lukewarm water — avoid cold drinks', '😷 Wear mask if you must step out briefly'];
        precautions = ['🚑 Call ambulance if you feel chest tightness or arm pain', 'Do NOT climb stairs — use elevator', 'Avoid stress and heavy meals', 'Keep aspirin accessible (doctor approved only)', 'Do not smoke or be near smokers'];
      } else if (hasOther) {
        level = 'Moderate Risk — Limit Exposure';
        emoji = '🟠';
        colorValue = 0xFFFF9800;
        canGoOutside = ['adult', 'teen', 'middle'].contains(ageGrp);
        message = 'Pollution is rising. Limit outdoor exertion to protect your health.';
        recommendations = ['🏠 Prefer indoor activities today', '😷 Wear a mask if you must go outside', '💧 Drink plenty of warm water', '💊 Strictly follow treatments for $customCond'];
        precautions = ['Avoid highly polluted areas like busy roads', 'Stop outdoor activities immediately if $customCond worsens'];
      } else {
        level = 'Moderate — Reduce Exposure';
        emoji = '🟠';
        colorValue = 0xFFFF9800;
        canGoOutside = ['adult', 'teen', 'middle'].contains(ageGrp);
        message = ['toddler', 'child', 'senior', 'elderly'].contains(ageGrp) ? 'Not safe for your age group. Stay indoors.' : 'Limit outdoor time. Wear mask during commute.';
        recommendations = _getHealthyModRec(ageGrp);
        precautions = _getHealthyModPrec(ageGrp);
      }
    } else if (aqi <= 300) {
      canGoOutside = false;
      if (hasRespiratory) {
        level = '🚨 EMERGENCY — Respiratory Crisis';
        emoji = '☠️';
        colorValue = 0xFF880000;
        message = 'CRITICAL! This air can cause severe asthma attack or COPD flare-up!';
        recommendations = _getRespiratoryPoorRec(ageGrp);
        precautions = _getRespiratoryPoorPrec(ageGrp);
      } else if (hasHeart) {
        level = '🚨 EMERGENCY — Heart Risk';
        emoji = '☠️';
        colorValue = 0xFF880000;
        message = 'CRITICAL! Pollution at this level can trigger cardiac events!';
        recommendations = ['🚫 ABSOLUTE indoor confinement', '🏠 Stay in room with air purifier', '💊 Take all heart medications on schedule', '🩺 Monitor BP and pulse every 2 hours', '📞 Inform your cardiologist about AQI level', '😷 N95 mask even while moving between rooms'];
        precautions = ['🚑 Call 108/ambulance immediately if chest pain occurs', 'Do NOT take hot showers — steam can stress heart', 'Eat light meals — avoid oily/heavy food', 'Keep GTN spray or prescribed emergency medicine nearby', 'Have someone stay with you — do not be alone', 'Avoid watching stressful news/content'];
      } else if (hasOther) {
        level = 'High Risk — Stay Indoors';
        emoji = '🔴';
        colorValue = 0xFFF44336;
        message = 'Unhealthy air quality. Stay indoors to avoid aggravating your condition.';
        recommendations = ['🚫 Avoid all outdoor activities', '🏠 Stay in a clean, indoor environment', '😷 Wear an N95 mask if you must step out briefly', '📞 Contact your doctor for advice regarding $customCond in high pollution'];
        precautions = ['Do not exert yourself physically', 'Monitor your health closely for any deterioration of $customCond'];
      } else {
        level = 'Poor — Everyone Stay Indoors';
        emoji = '🔴';
        colorValue = 0xFFF44336;
        message = 'Unhealthy for everyone. Avoid all outdoor activity.';
        recommendations = _getHealthyPoorRec(ageGrp);
        precautions = _getHealthyPoorPrec(ageGrp);
      }
    } else {
      level = '☠️ SEVERE — HEALTH EMERGENCY';
      emoji = '☠️';
      colorValue = 0xFF880000;
      canGoOutside = false;
      message = 'EXTREMELY DANGEROUS! Life-threatening air quality!';
      recommendations = _getSevereRec(ageGrp, hasRespiratory, hasHeart, hasAllergy, hasOther, customCond);
      precautions = _getSeverePrec(ageGrp, hasRespiratory, hasHeart, hasAllergy, hasOther, customCond);
    }

    if (hasOther && !primaryIsOther) {
      recommendations.add('🩺 Keep managing $customCond as prescribed by your doctor');
      precautions.add('Watch for any unexpected symptoms related to $customCond due to AQI levels');
    }

    List<String> conditionLabels = [];
    for (var s in _symptomOptions) {
      if (conditions.contains(s['key'])) {
        if (s['key'] == 'other') {
          conditionLabels.add(customCond.isNotEmpty ? 'Other: $customCond' : 'Other');
        } else {
          conditionLabels.add(s['label'] as String);
        }
      }
    }

    return {
      'level': level,
      'emoji': emoji,
      'color': colorValue,
      'canGoOutside': canGoOutside,
      'message': message,
      'recommendations': recommendations,
      'precautions': precautions,
      'riskMultiplier': riskMultiplier,
      'conditionLabels': conditionLabels,
      'age': age,
      'aqi': aqi,
      'ageGroup': ageGrp,
      'location': locationName,
    };
  }

  // --- Helpers for Recommendations ---
  List<String> _getRespiratoryGoodRec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['✅ Short outdoor play (30-45 min) is safe', '💊 Carry child\'s inhaler in school bag', '🏃 Light activities like walking are fine', '💧 Give water every 20 minutes during play'];
      case 'teen': return ['✅ Outdoor sports are okay today', '💊 Keep rescue inhaler in pocket', '🏃 Warm up slowly before exercise', '💧 Hydrate well before and after activity'];
      case 'senior' || 'elderly': return ['✅ Morning walk (6-8 AM) is safe', '💊 Take morning medications before going out', '🚶 Walk slowly — no need to rush', '💧 Carry water bottle'];
      default: return ['✅ Outdoor exercise is safe today', '💊 Carry rescue inhaler as backup', '🏃 You can jog or cycle freely', '💧 Stay hydrated during workouts'];
    }
  }

  List<String> _getRespiratoryGoodPrec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['Avoid dusty playgrounds or construction areas', 'Inform teacher about child\'s asthma condition', 'Watch for wheezing or rapid breathing'];
      case 'teen': return ['Stop immediately if you feel chest tightness', 'Avoid smoking zones even when passing by', 'Don\'t push through breathlessness during sports'];
      case 'senior' || 'elderly': return ['Walk with a companion for safety', 'Avoid morning fog — wait until it clears', 'Return home if you hear wheezing sounds', 'Keep phone charged with emergency contacts'];
      default: return ['Avoid exercising near busy roads', 'Stop activity if breathing feels labored', 'Know location of nearest hospital on your route'];
    }
  }

  List<String> _getRespiratorySatRec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['🏠 Keep child indoors — play inside', '🎨 Indoor activities: drawing, puzzles, reading', '💊 Give preventive dose if prescribed', '🫁 Watch for coughing or wheezing signs', '🪟 Keep windows closed'];
      case 'teen': return ['🏠 Skip outdoor sports practice today', '💊 Use preventive inhaler before any activity', '📚 Study indoors — avoid going to outdoor areas', '😷 Wear mask if going to school/college'];
      case 'senior' || 'elderly': return ['🏠 Stay indoors — skip morning walk today', '💊 Take medications on time', '🫁 Use steam inhalation for comfort', '💧 Drink warm water with tulsi or ginger', '📞 Inform family about air quality concern'];
      default: return ['🏠 Work from home if possible', '😷 Wear N95 mask for commute', '💊 Carry rescue inhaler at all times', '🚗 Keep car windows closed, use AC recirculation', '🏋️ Exercise indoors only (yoga, stretching)'];
    }
  }

  List<String> _getRespiratorySatPrec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['Do NOT send child to outdoor activities', 'Check inhaler expiry date today', 'Avoid using room fresheners — they irritate lungs', 'Keep emergency number on fridge'];
      case 'teen': return ['Do not participate in outdoor PE class', 'Avoid crowded areas — more dust and particles', 'Don\'t use deodorant sprays near face', 'Tell friends about your condition so they can help'];
      case 'senior' || 'elderly': return ['Do NOT exert yourself even inside the house', 'Avoid kitchen while cooking (smoke/fumes)', 'Keep nebulizer ready and charged', 'Have someone stay with you if possible'];
      default: return ['Avoid areas near construction sites', 'Don\'t smoke or be near smokers', 'Skip the gym — workout at home', 'If coughing increases, take rest immediately'];
    }
  }

  List<String> _getRespiratoryModRec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['🚫 DO NOT let child go outside', '🏠 Keep in sealed room with air purifier', '💊 Administer preventive nebulization', '🧸 Engage with indoor toys and games', '🪟 Seal windows with wet cloth if drafty', '💧 Give warm honey water (if age > 1)'];
      case 'teen': return ['🚫 Skip school if possible — air is dangerous', '😷 Double-layer mask if must go out', '💊 Use preventive inhaler 30 min before leaving', '🏠 Study in air-purified room', '📱 Keep emergency contacts on speed dial'];
      case 'senior' || 'elderly': return ['🚫 DO NOT step outside the house', '🏠 Stay in room with least outside exposure', '💊 Take all medications strictly on time', '🫁 Use nebulizer every 4-6 hours if prescribed', '💧 Sip warm liquids throughout the day', '📞 Call doctor for preventive advice'];
      default: return ['🚫 Avoid all outdoor activities', '🏠 Work from home — inform office about AQI', '😷 N95 mask mandatory if stepping out', '🫁 Use air purifier at home and office', '💊 Keep rescue inhaler in every bag/pocket', '💧 Drink 3-4 liters of warm water today'];
    }
  }

  List<String> _getRespiratoryModPrec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['🚑 Rush to hospital if child turns blue around lips', 'Watch for: fast breathing, rib pulling, inability to speak', 'Do NOT give cough syrup without doctor advice', 'Keep emergency bag ready (inhaler, medicines, documents)'];
      case 'teen': return ['Tell teachers about your condition — get indoor exemption', 'Avoid laughing gas/party smoke — extremely dangerous for you', 'If wheezing starts, sit upright and use inhaler immediately', 'Do NOT try to "push through" breathing difficulty'];
      case 'senior' || 'elderly': return ['🚑 Call 108 immediately if breathing becomes very difficult', 'Do NOT lie flat — sit propped up with pillows', 'Avoid hot/spicy food — can trigger coughing fits', 'Keep oxygen concentrator ready if prescribed', 'Have family member check on you every 2 hours'];
      default: return ['🚑 Go to ER if peak flow reading drops below 50%', 'Cancel travel plans — air in vehicles is worse', 'Avoid perfumes, incense, mosquito coils at home', 'Sleep with head elevated on 2 pillows tonight', 'Take sick leave — your lungs need protection'];
    }
  }

  List<String> _getRespiratoryPoorRec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['🚨 KEEP CHILD IN SEALED ROOM', '🫁 Run nebulizer every 4 hours', '💊 Give all prescribed emergency medicines', '😷 Child should wear mask even indoors', '📞 Call pediatrician NOW for advice', '🏥 Consider going to hospital for observation'];
      case 'senior' || 'elderly': return ['🚨 DO NOT LEAVE BED UNLESS NECESSARY', '🫁 Continuous oxygen if prescribed', '💊 All emergency medications NOW', '📞 Call pulmonologist immediately', '😷 N95 mask at ALL times', '🏥 Consider hospital admission for safety'];
      default: return ['🚨 COMPLETE INDOOR LOCKDOWN', '😷 N95 mask even inside house', '🫁 Air purifier on MAXIMUM', '💊 Use rescue inhaler preventively', '📞 Call doctor for emergency plan', '🏥 Go to hospital if ANY difficulty breathing'];
    }
  }

  List<String> _getRespiratoryPoorPrec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['🚑 Call ambulance if: blue lips, cannot cry, stops breathing', 'Do NOT give cold water or ice cream', 'Keep room between 22-25°C — not too cold or hot', 'Record breathing rate — share with doctor on call'];
      case 'senior' || 'elderly': return ['🚑 Call ambulance if: cannot speak full sentences, confusion', 'Keep hospital bag packed and ready', 'Do NOT take any new medicine without doctor approval', 'Family should monitor patient every 1 hour'];
      default: return ['🚑 Go to ER if: speaking becomes difficult, lips turn blue', 'Do NOT exercise at all — even stretching', 'Avoid showering with very hot water (steam can irritate)', 'Consider relocating temporarily to area with cleaner air'];
    }
  }

  List<String> _getAllergyGoodRec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['✅ Outdoor play is safe but avoid grassy fields', '🧴 Apply child-safe moisturizer before going out', '👕 Dress child in full sleeves to protect skin', '💧 Give plenty of water'];
    }
    return ['✅ Outdoor activities are fine', '💊 Carry antihistamine as backup', '🕶️ Wear sunglasses to protect eyes from dust', '🧴 Apply moisturizer if you have skin allergies'];
  }

  List<String> _getAllergyGoodPrec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['Shower child after outdoor play', 'Wash hands and face immediately after coming home', 'Avoid stuffed toys that collect dust'];
    }
    return ['Shower after returning from outside', 'Change clothes after outdoor exposure', 'Don\'t dry clothes outside — pollen can stick'];
  }

  List<String> _getAllergySatRec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['⚠️ Limit outdoor time to 20 minutes', '💊 Give antihistamine before going out', '😷 Use child-sized mask in dusty areas', '🧴 Heavy moisturizer for skin protection', '🪟 Keep bedroom windows closed'];
    }
    if (['senior', 'elderly'].contains(ageGrp)) {
      return ['⚠️ Avoid gardens and parks — pollen is higher', '💊 Take morning antihistamine on time', '👁️ Use lubricating eye drops', '🪟 Keep house sealed', '💧 Drink warm turmeric water for inflammation'];
    }
    return ['⚠️ Limit time in open/grassy areas', '💊 Take antihistamine before commute', '🕶️ Wear wraparound sunglasses', '😷 Mask in dusty or traffic areas', '🧴 Apply barrier cream on exposed skin'];
  }

  List<String> _getAllergySatPrec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['Don\'t let child rub eyes — use cold compress', 'Avoid parks with freshly cut grass', 'Wash child\'s hair before bedtime'];
    }
    if (['senior', 'elderly'].contains(ageGrp)) {
      return ['Avoid morning dew — allergens are concentrated', 'Use HEPA filter vacuum instead of broom', 'Don\'t use strong cleaning chemicals today'];
    }
    return ['Shower immediately after coming home', 'Don\'t touch face with unwashed hands', 'Clean AC filters — they trap allergens'];
  }

  List<String> _getAllergyModRec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['🏠 Keep child strictly indoors', '💊 Antihistamine + nasal spray as prescribed', '👁️ Cold compress on eyes if irritated', '🧴 Thick moisturizer every 3 hours for skin', '🫧 Use humidifier in child\'s room'];
    }
    return ['🏠 Stay indoors — allergens are very high', '💊 Double-check you took allergy medications', '👁️ Use antihistamine eye drops', '🧴 Apply calamine lotion for skin rashes', '😷 N95 mask if must go outside', '🪟 Seal all windows and doors'];
  }

  List<String> _getAllergyModPrec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['Watch for hives or swollen face — could be severe reaction', '🚑 Go to hospital if child has difficulty breathing + rash', 'Do NOT give adult allergy medicine to child'];
    }
    return ['Watch for anaphylaxis signs: swelling, difficulty breathing', 'Keep epinephrine auto-injector accessible if prescribed', 'Avoid eating outside food — cross-contamination risk higher'];
  }

  List<String> _getAllergyPoorRec(String ageGrp) {
    return ['🚫 ABSOLUTE indoor stay', '💊 Maximum allergy medication as prescribed', '👁️ Eye drops every 4 hours', '🫧 Run humidifier to keep air moist', '😷 Mask even indoors', '🧴 Full body moisturizer for skin allergies'];
  }

  List<String> _getAllergyPoorPrec(String ageGrp) {
    return ['🚑 Seek emergency care for severe swelling or breathing difficulty', 'Do NOT open windows or doors', 'Wet-mop floors — don\'t sweep', 'Remove carpets and curtains if possible — they trap allergens'];
  }

  List<String> _getMildGoodRec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['✅ Short outdoor time is fine', '💧 Keep child hydrated with warm fluids', '🍯 Honey + warm water for sore throat (age > 1)', '🧣 Cover nose and mouth in morning breeze'];
    }
    if (['senior', 'elderly'].contains(ageGrp)) {
      return ['✅ Brief morning sunlight (10 min) helps recovery', '💧 Drink ginger tea or warm turmeric milk', '🧣 Wrap a scarf around throat when going out', '💊 Continue cold/cough medication'];
    }
    return ['✅ Light outdoor activity is fine', '💧 Stay hydrated — warm water preferred', '🍋 Vitamin C-rich foods to boost immunity', '😴 Get adequate rest tonight'];
  }

  List<String> _getMildGoodPrec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['Don\'t let child share water bottles at school', 'Wash hands frequently to prevent spreading'];
    }
    if (['senior', 'elderly'].contains(ageGrp)) {
      return ['Don\'t skip meals — body needs energy to fight infection', 'Gargle with warm salt water before bed'];
    }
    return ['Avoid cold beverages', 'Cover mouth when coughing — protect others'];
  }

  List<String> _getMildSatRec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['🏠 Keep child at home to recover', '💧 Warm soup, dal water, or honey milk', '🧣 Keep chest and throat warm', '💊 Give prescribed cough syrup on time', '😴 Ensure afternoon nap for recovery'];
    }
    return ['🏠 Rest at home if possible', '😷 Wear mask to protect throat from dust', '💧 Warm water every hour', '💊 Take cold/cough medicine on schedule', '🍵 Herbal tea with honey helps recovery'];
  }

  List<String> _getMildSatPrec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['Don\'t send to school if fever is present', 'Watch for ear pain — common complication in children'];
    }
    return ['Pollution slows recovery — avoid unnecessary outings', 'If cough persists > 5 days, see a doctor', 'Avoid dairy if it increases mucus for you'];
  }

  List<String> _getMildModRec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['🏠 STRICTLY indoors — pollution worsens cold', '💊 All medicines on time', '🫧 Use steam vaporizer in room', '💧 Warm fluids every 30 minutes', '🪟 Keep windows sealed', '🧸 Keep child calm with indoor activities'];
    }
    return ['🏠 Stay home — polluted air will worsen symptoms', '😷 Mask even for short trips', '💊 Continue all medications', '🫧 Steam inhalation 2-3 times a day', '💧 Drink 3+ liters warm water', '🍯 Honey + ginger for throat relief'];
  }

  List<String> _getMildModPrec(String ageGrp) {
    if (['toddler', 'child'].contains(ageGrp)) {
      return ['🏥 See doctor if fever > 100.4°F', 'Watch for rapid breathing — could indicate pneumonia', 'Do NOT self-medicate — consult pediatrician'];
    }
    return ['See doctor if symptoms worsen in polluted air', 'Pollution + cold can lead to bronchitis — watch for yellow mucus', 'Avoid self-medicating with antibiotics'];
  }

  List<String> _getHealthyGoodRec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler': return ['✅ Perfect day for park visit!', '🧒 Let child play freely outdoors', '☀️ Apply sunscreen if sunny', '💧 Carry water bottle and snacks'];
      case 'child': return ['✅ Great day for outdoor games!', '⚽ Sports, cycling, running — all safe', '💧 Drink water every 20 min during play', '☀️ Wear cap if it\'s sunny'];
      case 'teen': return ['✅ Perfect for outdoor sports/practice', '🏃 Running, cycling, swimming — all good', '💧 Stay hydrated during exercise', '🎒 Enjoy outdoor activities freely'];
      case 'senior': return ['✅ Excellent day for morning walk', '🧘 Outdoor yoga or tai chi is safe', '💧 Carry water — hydrate well', '🌳 Visit a park — fresh air is beneficial'];
      case 'elderly': return ['✅ Short outdoor time in morning is good', '🚶 Gentle walking with support if needed', '☀️ Get 15 min sunlight for Vitamin D', '💧 Sip water regularly'];
      default: return ['✅ Enjoy any outdoor activity!', '🏃 Jogging, gym, sports — all safe', '🪟 Open windows for fresh air at home', '💧 Great day to be active outside'];
    }
  }

  List<String> _getHealthySatRec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['✅ Outdoor play is fine but limit to 1 hour', '💧 Keep child hydrated', '🏠 Prefer indoor play if dusty outside', '😷 No mask needed for healthy children'];
      case 'senior' || 'elderly': return ['⚠️ Walk in morning only (6-8 AM) when air is fresher', '💧 Drink warm water', '🏠 Prefer indoor activities in afternoon', '🧘 Indoor yoga or light exercise'];
      default: return ['✅ Normal activities are fine', '🏃 Moderate outdoor exercise is okay', '💧 Stay hydrated', '⚠️ Avoid peak traffic hours for jogging'];
    }
  }

  List<String> _getHealthySatPrec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['Avoid playing near roads or construction', 'Wash hands and face after coming home'];
      case 'senior' || 'elderly': return ['Don\'t overexert during walk', 'Come back inside if air feels hazy'];
      default: return ['Reduce outdoor exercise if air feels stuffy', 'Avoid exercising near main roads'];
    }
  }

  List<String> _getHealthyModRec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler': return ['🏠 Keep toddler indoors', '🎨 Indoor play activities', '🪟 Close all windows', '💧 Extra fluids today'];
      case 'child': return ['🏠 No outdoor games today', '📚 Indoor activities only', '😷 Mask if going to school', '💧 Drink more water than usual'];
      case 'teen': return ['⚠️ Skip outdoor sports', '😷 Wear mask for commute', '🏠 Study indoors', '🏋️ Indoor exercise only'];
      case 'senior' || 'elderly': return ['🏠 Stay indoors all day', '🪟 Seal windows', '💧 Warm fluids throughout day', '📞 Stay connected with family'];
      default: return ['😷 Wear mask during commute', '🏠 Work from home if possible', '🏋️ Indoor gym only', '🪟 Keep windows closed', '💧 Increase water intake'];
    }
  }

  List<String> _getHealthyModPrec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['Watch for new cough or eye rubbing', 'Don\'t use mosquito coils — adds to pollution'];
      case 'senior' || 'elderly': return ['Monitor for any new breathing difficulty', 'Don\'t skip medications', 'Avoid going to market — order delivery instead'];
      default: return ['Avoid roadside food stalls (smoke + pollution)', 'Don\'t jog or run outdoors', 'Monitor for headache or eye irritation'];
    }
  }

  List<String> _getHealthyPoorRec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['🚫 Child MUST stay indoors', '🫁 Use air purifier in child\'s room', '😷 Mask even indoors if no purifier', '🪟 Seal all gaps in windows/doors', '💧 Warm water and nutritious food'];
      case 'senior' || 'elderly': return ['🚫 Do NOT go outside at all', '🏠 Stay in cleanest room', '😷 Wear mask if moving around house', '💧 Drink warm water every 30 min', '📞 Keep doctor\'s number handy'];
      default: return ['🚫 Avoid ALL outdoor activities', '😷 N95 mask if must go outside', '🏠 Stay indoors with windows sealed', '🫁 Air purifier on high', '💧 Drink plenty of fluids'];
    }
  }

  List<String> _getHealthyPoorPrec(String ageGrp) {
    switch (ageGrp) {
      case 'toddler' || 'child': return ['Even healthy children can develop breathing issues at this AQI', 'Watch for persistent cough — see doctor if it starts'];
      case 'senior' || 'elderly': return ['Even without prior conditions, this AQI can cause problems', 'Monitor for chest discomfort or unusual fatigue'];
      default: return ['Even healthy adults can feel effects at this AQI level', 'If you develop persistent cough or headache, see a doctor', 'Avoid cooking with gas — use electric if possible'];
    }
  }

  List<String> _getSevereRec(String ageGrp, bool resp, bool heart, bool allergy, bool other, String customCond) {
    List<String> recs = [
      '🚫 NOBODY should go outside',
      '🏠 Stay in completely sealed room',
      '😷 N95 mask mandatory even indoors',
      '🫁 Air purifier on MAXIMUM',
      '💧 Drink warm water every 30 minutes',
      '🪟 Seal window gaps with wet towels',
    ];
    if (resp) {
      recs.insert(0, '🚨 ASTHMA/COPD: Use nebulizer preventively every 4 hours!');
      recs.add('💊 Take ALL emergency respiratory medications');
    }
    if (heart) {
      recs.insert(0, '❤️ HEART PATIENTS: Check BP every 2 hours!');
      recs.add('💊 Heart medication strictly on schedule');
    }
    if (allergy) {
      recs.add('👁️ Antihistamine eye drops every 4 hours');
      recs.add('🧴 Full body moisturizer to protect skin');
    }
    if (other) {
      recs.add('📞 Consult your doctor immediately regarding $customCond during this AQI crisis');
    }
    if (['toddler', 'child'].contains(ageGrp)) {
      recs.insert(0, '👶 CHILDREN: Keep in safest, most sealed room!');
    }
    if (['senior', 'elderly'].contains(ageGrp)) {
      recs.insert(0, '👴 ELDERLY: Someone must stay with you at all times!');
    }
    return recs;
  }

  List<String> _getSeverePrec(String ageGrp, bool resp, bool heart, bool allergy, bool other, String customCond) {
    List<String> precs = [
      '🚑 Call ambulance immediately if ANY breathing difficulty',
      'Do NOT exercise at all — even indoors',
      'Do NOT cook with gas — order food or use microwave',
      'Do NOT burn incense, candles, or mosquito coils',
      'Keep emergency hospital bag packed and ready',
    ];
    if (resp) {
      precs.add('ASTHMA: If rescue inhaler doesn\'t help in 15 min → Go to ER');
      precs.add('Consider temporary relocation to area with cleaner air');
    }
    if (heart) {
      precs.add('HEART: Go to ER immediately if chest pain or arm numbness');
      precs.add('Avoid hot showers — steam stresses heart in polluted air');
    }
    if (other) {
      precs.add('Monitor closely for any severe worsening of $customCond');
    }
    if (['toddler', 'child'].contains(ageGrp)) {
      precs.add('CHILD: Rush to hospital if blue lips, fast breathing, or not responding');
    }
    if (['senior', 'elderly'].contains(ageGrp)) {
      precs.add('ELDERLY: Family must check every 1 hour');
      precs.add('Keep oxygen concentrator ready if available');
    }
    return precs;
  }

  Widget _infoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCitySearch ? 'City Health Advisory' : 'Current Location Advisory'),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching real-time Air Quality data...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : _currentStep == 1 
          ? _buildStep1() 
          : _currentStep == 2 
            ? _buildStep2() 
            : _buildStep3(),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Text('1️⃣', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isCitySearch ? 'Enter City and Age' : 'Enter Your Age', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  )
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (widget.isCitySearch) ...[
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                _typedCityInput = textEditingValue.text; // Store typed text
                return await _getCitySuggestions(textEditingValue.text);
              },
              displayStringForOption: (option) {
                return [option['name'], option['admin1'], option['country']].where((s) => s != null && s.toString().isNotEmpty).join(', ');
              },
              onSelected: (selection) {
                _selectedCityData = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search City',
                    hintText: 'e.g. Kadapa, New York',
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    _typedCityInput = val;
                    _selectedCityData = null; // Clear exact selection if user keeps typing
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 40, 
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          final displayString = [option['name'], option['admin1'], option['country']]
                            .where((s) => s != null && s.toString().isNotEmpty)
                            .join(', ');
                            
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.blue),
                            title: Text(displayString),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Your Age',
              hintText: 'e.g. 25',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _nextStep,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Step', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Text('2️⃣', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Your Health Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Age: ${_ageController.text} years', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Choose all that apply. Select "None" if healthy.', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _symptomOptions.map((s) {
              final sel = _selectedSymptoms.contains(s['key']);
              return FilterChip(
                selected: sel,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s['icon'] as IconData, size: 18, color: sel ? Colors.white : s['color'] as Color),
                    const SizedBox(width: 6),
                    Text(s['label'] as String, style: TextStyle(fontSize: 13, color: sel ? Colors.white : Colors.black87)),
                  ],
                ),
                selectedColor: s['key'] == 'none' ? Colors.green : (s['color'] as Color),
                checkmarkColor: Colors.white,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (_) => _onSymptomToggle(s['key'] as String),
              );
            }).toList(),
          ),
          if (_selectedSymptoms.contains('other'))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: TextField(
                controller: _otherSymptomController,
                decoration: InputDecoration(
                  labelText: 'Please describe your condition',
                  hintText: 'e.g., Diabetes, Migraines, etc.',
                  prefixIcon: const Icon(Icons.edit_note, color: Colors.blueGrey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ),
          if (!_selectedSymptoms.contains('none'))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Selected: ${_selectedSymptoms.length} condition(s)', style: const TextStyle(fontSize: 13, color: Colors.orange))),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _backStep,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getAdvice,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Get Advisory'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Text('3️⃣', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(child: Text('Your Health Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_advice != null) _buildAdviceCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _backStep,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Start completely over by popping back to the Option Selection screen
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Finish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAdviceCard() {
    final a = _advice!;
    final color = Color(a['color'] as int);
    final recs = a['recommendations'] as List<String>;
    final precs = a['precautions'] as List<String>;
    final labels = a['conditionLabels'] as List<String>;

    return Column(
      children: [
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color, width: 2)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(a['emoji'] as String, style: const TextStyle(fontSize: 50)),
                const SizedBox(height: 8),
                Text(a['level'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_pin, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(a['location'], style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (a['canGoOutside'] as bool) ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (a['canGoOutside'] as bool) ? Colors.green : Colors.red),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon((a['canGoOutside'] as bool) ? Icons.check_circle : Icons.cancel, color: (a['canGoOutside'] as bool) ? Colors.green : Colors.red, size: 28),
                      const SizedBox(width: 8),
                      Text((a['canGoOutside'] as bool) ? '✅ Safe to go outside' : '🚫 Stay indoors!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: (a['canGoOutside'] as bool) ? Colors.green : Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(a['message'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _infoChip('Age: ${a['age']} (${a['ageGroup']})', Icons.person, Colors.blue),
                    _infoChip('AQI: ${a['aqi']}', Icons.air, color),
                    _infoChip('Risk: ${((a['riskMultiplier'] as double) * 100).round() - 100}% higher', Icons.warning, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (labels.isNotEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.medical_information, color: Colors.orange), SizedBox(width: 8), Text('Your Health Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange))]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: labels.map((l) => Chip(label: Text(l, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.orange.shade100, visualDensity: VisualDensity.compact)).toList()),
                ],
              ),
            ),
          ),
        if (labels.isNotEmpty) const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.recommend, color: Colors.green), SizedBox(width: 8), Text('Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green))]),
                const SizedBox(height: 10),
                ...recs.map((r) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(r, style: const TextStyle(fontSize: 14)))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (precs.isNotEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.shield, color: Colors.red), SizedBox(width: 8), Text('Precautions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red))]),
                  const SizedBox(height: 10),
                  ...precs.map((p) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('⚠️ ', style: TextStyle(fontSize: 14)), Expanded(child: Text(p, style: const TextStyle(fontSize: 14)))]))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _otherSymptomController.dispose();
    super.dispose();
  }
}