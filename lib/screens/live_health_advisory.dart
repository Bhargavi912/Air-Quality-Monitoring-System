import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';

class HealthAdvisoryScreen extends StatefulWidget {
  const HealthAdvisoryScreen({super.key});

  @override
  State<HealthAdvisoryScreen> createState() => _HealthAdvisoryScreenState();
}

class _HealthAdvisoryScreenState extends State<HealthAdvisoryScreen> {
  final TextEditingController _ageController = TextEditingController();
  Map<String, dynamic>? _advice;
  int _page = 0; // 0=Age, 1=Symptoms, 2=Results

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
  ];

  final Set<String> _selectedSymptoms = {'none'};

  void _onSymptomToggle(String key) {
    setState(() {
      if (key == 'none') {
        _selectedSymptoms.clear();
        _selectedSymptoms.add('none');
      } else {
        _selectedSymptoms.remove('none');
        if (_selectedSymptoms.contains(key)) {
          _selectedSymptoms.remove(key);
          if (_selectedSymptoms.isEmpty) _selectedSymptoms.add('none');
        } else {
          _selectedSymptoms.add(key);
        }
      }
    });
  }

  void _goToSymptoms() {
    final age = int.tryParse(_ageController.text);
    if (age == null || age <= 0 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age (1-120)'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _page = 1);
  }

  void _getAdvice() {
    final age = int.tryParse(_ageController.text);
    if (age == null) return;
    final provider = context.read<AirQualityProvider>();
    if (provider.currentAqi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AQI data not loaded. Go to Dashboard first.'), backgroundColor: Colors.orange),
      );
      return;
    }
    final aqi = provider.currentAqi!.standardAqi;
    final conditions = _selectedSymptoms.where((s) => s != 'none').toList();
    setState(() {
      _advice = _generateAdvice(age: age, aqi: aqi, conditions: conditions, pm25: provider.currentAqi!.pm25);
      _page = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _page == 0 ? '👤 Health Advisory' : _page == 1 ? '🩺 Health Conditions' : '📋 Your Advisory',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_page > 0) {
              setState(() => _page--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        child: _page == 0
            ? _buildAgePage()
            : _page == 1
                ? _buildSymptomsPage()
                : _buildResultsPage(),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // PAGE 1: ENTER AGE
  // ═══════════════════════════════════════════════
  Widget _buildAgePage() {
    return SingleChildScrollView(
      key: const ValueKey('age_page'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Big Icon
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF26DE81), Color(0xFF20BF6B)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF26DE81).withAlpha(80), blurRadius: 20, spreadRadius: 5)],
            ),
            child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 30),
          const Text('Step 1 of 3', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Enter Your Age', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'We personalize health advice based on\nyour age group and vulnerability level',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 40),

          // Age Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, spreadRadius: 5)],
            ),
            child: TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'e.g. 25',
                hintStyle: TextStyle(fontSize: 32, color: Colors.grey.shade300),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Icon(Icons.cake_rounded, size: 28, color: Color(0xFF26DE81)),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              ),
              onSubmitted: (_) => _goToSymptoms(),
            ),
          ),
          const SizedBox(height: 16),

          // Age Group Preview
          if (_ageController.text.isNotEmpty && int.tryParse(_ageController.text) != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF26DE81).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Age Group: ${_getAgeGroupLabel(int.parse(_ageController.text))}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF20BF6B), fontWeight: FontWeight.w600),
              ),
            ),

          const SizedBox(height: 40),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _goToSymptoms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26DE81),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF26DE81).withAlpha(100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Next — Select Health Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Age Group Reference
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 Age Group Classification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _ageGroupRow('≤ 5', 'Toddler', 'Very High Risk', Colors.red),
                _ageGroupRow('6-12', 'Child', 'High Risk', Colors.orange),
                _ageGroupRow('13-17', 'Teen', 'Normal', Colors.green),
                _ageGroupRow('18-45', 'Adult', 'Normal', Colors.green),
                _ageGroupRow('46-60', 'Middle Aged', 'Moderate Risk', Colors.amber),
                _ageGroupRow('61-75', 'Senior', 'High Risk', Colors.orange),
                _ageGroupRow('75+', 'Elderly', 'Very High Risk', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ageGroupRow(String range, String group, String risk, Color color) {
    final age = int.tryParse(_ageController.text);
    bool isActive = false;
    if (age != null) {
      final g = _ageGroup(age);
      isActive = g == group.toLowerCase() || (g == 'middle' && group == 'Middle Aged');
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(range, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
          SizedBox(width: 90, child: Text(group, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
            child: Text(risk, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ),
          if (isActive) ...[const Spacer(), Text('◄ You', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))],
        ],
      ),
    );
  }

  String _getAgeGroupLabel(int age) {
    if (age <= 5) return 'Toddler (Very High Risk)';
    if (age <= 12) return 'Child (High Risk)';
    if (age <= 17) return 'Teen (Normal)';
    if (age <= 45) return 'Adult (Normal)';
    if (age <= 60) return 'Middle Aged (Moderate Risk)';
    if (age <= 75) return 'Senior (High Risk)';
    return 'Elderly (Very High Risk)';
  }

  // ═══════════════════════════════════════════════
  // PAGE 2: SELECT SYMPTOMS
  // ═══════════════════════════════════════════════
  Widget _buildSymptomsPage() {
    final age = int.tryParse(_ageController.text) ?? 0;
    return SingleChildScrollView(
      key: const ValueKey('symptoms_page'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Big Icon
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4B7BEC), Color(0xFF3867D6)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF4B7BEC).withAlpha(80), blurRadius: 20, spreadRadius: 5)],
            ),
            child: const Icon(Icons.medical_services_rounded, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('Step 2 of 3', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Select Health Conditions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Age: $age (${_getAgeGroupLabel(age).split(' (').first})',
            style: const TextStyle(fontSize: 14, color: Color(0xFF26DE81), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose all conditions that apply.\nSelect "None" if you are healthy.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Symptom Grid
          ...List.generate(_symptomOptions.length, (i) {
            final s = _symptomOptions[i];
            final sel = _selectedSymptoms.contains(s['key']);
            final color = s['color'] as Color;
            return GestureDetector(
              onTap: () => _onSymptomToggle(s['key'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? color.withAlpha(20) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? color : Colors.grey.shade200, width: sel ? 2 : 1),
                  boxShadow: sel
                      ? [BoxShadow(color: color.withAlpha(30), blurRadius: 10, spreadRadius: 2)]
                      : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: sel ? color.withAlpha(40) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(s['icon'] as IconData, color: sel ? color : Colors.grey.shade400, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        s['label'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? color : Colors.black87,
                        ),
                      ),
                    ),
                    if (sel)
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 18),
                      )
                    else
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          // Selected Count
          if (!_selectedSymptoms.contains('none'))
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedSymptoms.length} condition(s) selected — Advisory will be more cautious',
                    style: const TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Get Advisory Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _getAdvice,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B7BEC),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF4B7BEC).withAlpha(100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety_rounded, size: 22),
                  SizedBox(width: 8),
                  Text('Get Health Advisory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // PAGE 3: RESULTS
  // ═══════════════════════════════════════════════
  Widget _buildResultsPage() {
    if (_advice == null) return const Center(child: Text('No data'));
    final a = _advice!;
    final color = Color(a['color'] as int);
    final recs = a['recommendations'] as List<String>;
    final precs = a['precautions'] as List<String>;
    final labels = a['conditionLabels'] as List<String>;
    final canGoOut = a['canGoOutside'] as bool;

    return SingleChildScrollView(
      key: const ValueKey('results_page'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Step 3 of 3', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Your Personalized Advisory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Main Result Card
          Card(
            elevation: 8,
            shadowColor: color.withAlpha(60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: color, width: 2)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(a['emoji'] as String, style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  Text(a['level'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
                  const SizedBox(height: 16),

                  // Safe / Not Safe
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: canGoOut ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: canGoOut ? Colors.green : Colors.red, width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(canGoOut ? Icons.check_circle_rounded : Icons.cancel_rounded, color: canGoOut ? Colors.green : Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          canGoOut ? '✅ Safe to Go Outside' : '🚫 Stay Indoors!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: canGoOut ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(a['message'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
                  const SizedBox(height: 16),

                  // Info Chips
                  Wrap(
                    spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                    children: [
                      _infoChip('Age: ${a['age']} (${(a['ageGroup'] as String).substring(0, 1).toUpperCase()}${(a['ageGroup'] as String).substring(1)})', Icons.person, Colors.blue),
                      _infoChip('AQI: ${a['aqi']}', Icons.air, color),
                      _infoChip('Risk: ${((a['riskMultiplier'] as double) * 100).round() - 100}% ↑', Icons.warning_rounded, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Health Conditions Card
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
                    const Row(children: [
                      Icon(Icons.medical_information_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Your Health Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: labels.map((l) => Chip(
                        label: Text(l, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.orange.shade100,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          if (labels.isNotEmpty) const SizedBox(height: 12),

          // Recommendations Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.recommend_rounded, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  ]),
                  const SizedBox(height: 12),
                  ...recs.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                        Expanded(child: Text(r, style: const TextStyle(fontSize: 14, height: 1.3))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Precautions Card
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
                    const Row(children: [
                      Icon(Icons.shield_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Precautions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    ]),
                    const SizedBox(height: 12),
                    ...precs.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                          Expanded(child: Text(p, style: const TextStyle(fontSize: 14, height: 1.3))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Start Over Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _page = 0;
                _advice = null;
                _ageController.clear();
                _selectedSymptoms.clear();
                _selectedSymptoms.add('none');
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Start Over', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withAlpha(80))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ═══════════ ALL EXISTING LOGIC BELOW — UNCHANGED ═══════════

  String _ageGroup(int age) {
    if (age <= 5) return 'toddler';
    if (age <= 12) return 'child';
    if (age <= 17) return 'teen';
    if (age <= 45) return 'adult';
    if (age <= 60) return 'middle';
    if (age <= 75) return 'senior';
    return 'elderly';
  }

  Map<String, dynamic> _generateAdvice({required int age, required int aqi, required List<String> conditions, required double pm25}) {
    final ageGrp = _ageGroup(age);
    bool hasRespiratory = conditions.any((c) => ['asthma', 'bronchitis', 'copd', 'breathing'].contains(c));
    bool hasHeart = conditions.contains('heart');
    bool hasAllergy = conditions.any((c) => ['allergy', 'sinusitis', 'eye_irritation', 'skin'].contains(c));
    bool hasMild = conditions.any((c) => ['cold', 'cough', 'throat', 'headache'].contains(c));

    double riskMultiplier = 1.0;
    if (['toddler', 'child', 'senior', 'elderly'].contains(ageGrp)) riskMultiplier += 0.5;
    if (ageGrp == 'toddler' || ageGrp == 'elderly') riskMultiplier += 0.3;
    if (hasRespiratory) riskMultiplier += 1.0;
    if (hasHeart) riskMultiplier += 0.8;
    if (hasAllergy) riskMultiplier += 0.5;
    if (hasMild) riskMultiplier += 0.3;

    String level; String emoji; int colorValue; bool canGoOutside; String message;
    List<String> recommendations = []; List<String> precautions = [];

    if (aqi <= 50) {
      if (hasRespiratory) { level='Good — Carry Medication'; emoji='⚠️'; colorValue=0xFFC6CC00; canGoOutside=true; message='Air is clean but always be prepared.'; recommendations=_getRespiratoryGoodRec(ageGrp); precautions=_getRespiratoryGoodPrec(ageGrp); }
      else if (hasHeart) { level='Good — Light Activity OK'; emoji='✅'; colorValue=0xFF4CAF50; canGoOutside=true; message='Air quality is great. Light outdoor activities are safe.'; recommendations=['✅ Light walking in parks is safe','💊 Carry heart medication','💧 Stay hydrated','🩺 Monitor heart rate']; precautions=['Avoid sudden intense exercise','Rest if chest discomfort','Stay in shaded areas']; }
      else if (hasAllergy) { level='Good — Watch for Triggers'; emoji='✅'; colorValue=0xFF4CAF50; canGoOutside=true; message='Air is good but pollen/dust may cause issues.'; recommendations=_getAllergyGoodRec(ageGrp); precautions=_getAllergyGoodPrec(ageGrp); }
      else if (hasMild) { level='Good — Rest Recommended'; emoji='✅'; colorValue=0xFF4CAF50; canGoOutside=true; message='Air is clean. Focus on recovering.'; recommendations=_getMildGoodRec(ageGrp); precautions=_getMildGoodPrec(ageGrp); }
      else { level='Good'; emoji='✅'; colorValue=0xFF4CAF50; canGoOutside=true; message='Air quality is excellent!'; recommendations=_getHealthyGoodRec(ageGrp); precautions=[]; }
    } else if (aqi <= 100) {
      if (hasRespiratory) { level='Moderate Risk for You'; emoji='🟠'; colorValue=0xFFFF9800; canGoOutside=false; message='Air may trigger your respiratory condition.'; recommendations=_getRespiratorySatRec(ageGrp); precautions=_getRespiratorySatPrec(ageGrp); }
      else if (hasHeart) { level='Satisfactory — Limit Exertion'; emoji='🟡'; colorValue=0xFFC6CC00; canGoOutside=true; message='Avoid heavy physical work.'; recommendations=['⚠️ Limit outdoor activity to 30 min','🚶 Slow walking only','💊 Take morning medication','💧 Warm water regularly','🏠 Indoor exercise preferred']; precautions=['Avoid busy roads','Monitor BP','Stop if dizzy','Avoid peak traffic hours']; }
      else if (hasAllergy) { level='Satisfactory — Allergy Alert'; emoji='🟡'; colorValue=0xFFC6CC00; canGoOutside=true; message='Air okay but allergens may be present.'; recommendations=_getAllergySatRec(ageGrp); precautions=_getAllergySatPrec(ageGrp); }
      else if (hasMild) { level='Satisfactory — Take Care'; emoji='🟡'; colorValue=0xFFC6CC00; canGoOutside=true; message='Your cold/cough may feel slightly worse.'; recommendations=_getMildSatRec(ageGrp); precautions=_getMildSatPrec(ageGrp); }
      else { level='Satisfactory'; emoji='🟡'; colorValue=0xFFC6CC00; canGoOutside=true; message='Air is acceptable for most.'; recommendations=_getHealthySatRec(ageGrp); precautions=_getHealthySatPrec(ageGrp); }
    } else if (aqi <= 200) {
      if (hasRespiratory) { level='DANGEROUS for You!'; emoji='🚨'; colorValue=0xFFD32F2F; canGoOutside=false; message='VERY HIGH RISK! Your lungs cannot handle this.'; recommendations=_getRespiratoryModRec(ageGrp); precautions=_getRespiratoryModPrec(ageGrp); }
      else if (hasHeart) { level='High Risk — Stay Indoors'; emoji='🔴'; colorValue=0xFFF44336; canGoOutside=false; message='Pollution can trigger heart complications.'; recommendations=['🚫 Cancel outdoor plans','🏠 Air-conditioned room','💊 Heart medication on schedule','🩺 Check BP every 3 hours','💧 Lukewarm water','😷 N95 mask if stepping out']; precautions=['🚑 Call ambulance if chest pain','Use elevator not stairs','Light meals only','Keep emergency medicine nearby']; }
      else if (hasAllergy) { level='Unhealthy — Allergy Danger'; emoji='🟠'; colorValue=0xFFFF9800; canGoOutside=false; message='High allergen levels. Symptoms will worsen.'; recommendations=_getAllergyModRec(ageGrp); precautions=_getAllergyModPrec(ageGrp); }
      else if (hasMild) { level='Unhealthy — Recovery at Risk'; emoji='🟠'; colorValue=0xFFFF9800; canGoOutside=false; message='Polluted air will slow recovery.'; recommendations=_getMildModRec(ageGrp); precautions=_getMildModPrec(ageGrp); }
      else { level='Moderate — Reduce Exposure'; emoji='🟠'; colorValue=0xFFFF9800; canGoOutside=['adult','teen','middle'].contains(ageGrp); message=['toddler','child','senior','elderly'].contains(ageGrp)?'Not safe for your age group.':'Limit outdoor time. Wear mask.'; recommendations=_getHealthyModRec(ageGrp); precautions=_getHealthyModPrec(ageGrp); }
    } else if (aqi <= 300) {
      canGoOutside = false;
      if (hasRespiratory) { level='🚨 EMERGENCY — Respiratory Crisis'; emoji='☠️'; colorValue=0xFF880000; message='CRITICAL! Severe attack risk!'; recommendations=_getRespiratoryPoorRec(ageGrp); precautions=_getRespiratoryPoorPrec(ageGrp); }
      else if (hasHeart) { level='🚨 EMERGENCY — Heart Risk'; emoji='☠️'; colorValue=0xFF880000; message='CRITICAL! Can trigger cardiac events!'; recommendations=['🚫 ABSOLUTE indoor confinement','🏠 Air purifier room','💊 All medications on schedule','🩺 Monitor BP every 2 hours','📞 Inform cardiologist','😷 N95 mask between rooms']; precautions=['🚑 Call 108 if chest pain','Light meals only','Keep GTN spray nearby','Do not be alone']; }
      else if (hasAllergy) { level='Severe — Allergy Emergency'; emoji='🔴'; colorValue=0xFFF44336; message='Extreme allergen risk.'; recommendations=_getAllergyPoorRec(ageGrp); precautions=_getAllergyPoorPrec(ageGrp); }
      else { level='Poor — Everyone Stay Indoors'; emoji='🔴'; colorValue=0xFFF44336; message='Unhealthy for everyone.'; recommendations=_getHealthyPoorRec(ageGrp); precautions=['Even healthy people can feel effects','See doctor if persistent cough','Avoid gas cooking']; }
    } else {
      level='☠️ SEVERE — HEALTH EMERGENCY'; emoji='☠️'; colorValue=0xFF880000; canGoOutside=false; message='EXTREMELY DANGEROUS!';
      recommendations=_getSevereRec(ageGrp, hasRespiratory, hasHeart, hasAllergy); precautions=_getSeverePrec(ageGrp, hasRespiratory, hasHeart, hasAllergy);
    }

    List<String> conditionLabels = [];
    for (var s in _symptomOptions) { if (conditions.contains(s['key'])) conditionLabels.add(s['label'] as String); }

    return {'level':level,'emoji':emoji,'color':colorValue,'canGoOutside':canGoOutside,'message':message,'recommendations':recommendations,'precautions':precautions,'riskMultiplier':riskMultiplier,'conditionLabels':conditionLabels,'age':age,'aqi':aqi,'ageGroup':ageGrp};
  }

  // ═══════ ALL HELPER METHODS — SAME AS YOUR ORIGINAL ═══════
  List<String> _getRespiratoryGoodRec(String g) { switch(g){ case 'toddler': case 'child': return ['✅ Short outdoor play (30-45 min) is safe','💊 Carry inhaler in school bag','🏃 Light activities are fine','💧 Give water every 20 min']; case 'teen': return ['✅ Outdoor sports okay','💊 Keep rescue inhaler','🏃 Warm up slowly','💧 Hydrate well']; case 'senior': case 'elderly': return ['✅ Morning walk (6-8 AM) safe','💊 Take medications before going out','🚶 Walk slowly','💧 Carry water']; default: return ['✅ Outdoor exercise safe','💊 Carry rescue inhaler','🏃 Jog or cycle freely','💧 Stay hydrated']; } }
  List<String> _getRespiratoryGoodPrec(String g) { switch(g){ case 'toddler': case 'child': return ['Avoid dusty playgrounds','Inform teacher about asthma','Watch for wheezing']; case 'teen': return ['Stop if chest tightness','Avoid smoking zones','Don\'t push through breathlessness']; case 'senior': case 'elderly': return ['Walk with companion','Avoid morning fog','Return if wheezing','Keep phone charged']; default: return ['Avoid busy roads','Stop if breathing labored','Know nearest hospital']; } }
  List<String> _getRespiratorySatRec(String g) { switch(g){ case 'toddler': case 'child': return ['🏠 Keep child indoors','🎨 Indoor activities','💊 Give preventive dose','🫁 Watch for coughing','🪟 Close windows']; case 'teen': return ['🏠 Skip outdoor sports','💊 Preventive inhaler','📚 Study indoors','😷 Mask to school']; case 'senior': case 'elderly': return ['🏠 Skip morning walk','💊 Medications on time','🫁 Steam inhalation','💧 Warm water with tulsi','📞 Inform family']; default: return ['🏠 Work from home','😷 N95 for commute','💊 Carry inhaler','🚗 AC recirculation','🏋️ Indoor exercise only']; } }
  List<String> _getRespiratorySatPrec(String g) { switch(g){ case 'toddler': case 'child': return ['No outdoor activities','Check inhaler expiry','Avoid room fresheners','Keep emergency number ready']; case 'teen': return ['No outdoor PE','Avoid crowded areas','Avoid sprays near face','Tell friends about condition']; case 'senior': case 'elderly': return ['Don\'t exert even indoors','Avoid kitchen while cooking','Keep nebulizer ready','Have someone stay with you']; default: return ['Avoid construction sites','Don\'t smoke','Skip gym','Rest if coughing increases']; } }
  List<String> _getRespiratoryModRec(String g) { switch(g){ case 'toddler': case 'child': return ['🚫 DO NOT let child go outside','🏠 Sealed room with air purifier','💊 Preventive nebulization','🧸 Indoor toys and games','🪟 Seal windows','💧 Warm honey water (age>1)']; case 'teen': return ['🚫 Skip school if possible','😷 Double-layer mask','💊 Preventive inhaler 30 min before','🏠 Air-purified room','📱 Emergency contacts ready']; case 'senior': case 'elderly': return ['🚫 DO NOT step outside','🏠 Least-exposed room','💊 All medications strictly','🫁 Nebulizer every 4-6 hrs','💧 Warm liquids all day','📞 Call doctor']; default: return ['🚫 Avoid all outdoor','🏠 Work from home','😷 N95 mandatory','🫁 Air purifier','💊 Rescue inhaler everywhere','💧 3-4L warm water']; } }
  List<String> _getRespiratoryModPrec(String g) { switch(g){ case 'toddler': case 'child': return ['🚑 Hospital if blue lips/fast breathing','Watch for rib pulling','No cough syrup without doctor','Emergency bag ready']; case 'teen': return ['Get indoor PE exemption','Avoid smoke/fumes','Sit upright if wheezing','Don\'t push through difficulty']; case 'senior': case 'elderly': return ['🚑 Call 108 if breathing very difficult','Sit propped up','Avoid hot/spicy food','Keep oxygen concentrator ready','Check every 2 hours']; default: return ['🚑 ER if peak flow drops','Cancel travel','Avoid perfumes/incense','Sleep elevated','Take sick leave']; } }
  List<String> _getRespiratoryPoorRec(String g) { switch(g){ case 'toddler': case 'child': return ['🚨 SEALED ROOM','🫁 Nebulizer every 4 hrs','💊 Emergency medicines','😷 Mask even indoors','📞 Call pediatrician','🏥 Consider hospital']; case 'senior': case 'elderly': return ['🚨 DON\'T LEAVE BED','🫁 Continuous oxygen','💊 All emergency meds','📞 Call pulmonologist','😷 N95 always','🏥 Consider admission']; default: return ['🚨 INDOOR LOCKDOWN','😷 N95 even inside','🫁 Purifier on MAX','💊 Rescue inhaler preventively','📞 Call doctor','🏥 Hospital if ANY difficulty']; } }
  List<String> _getRespiratoryPoorPrec(String g) { switch(g){ case 'toddler': case 'child': return ['🚑 Ambulance if blue lips/stops breathing','No cold water','Room 22-25°C','Record breathing rate']; case 'senior': case 'elderly': return ['🚑 Ambulance if can\'t speak/confusion','Hospital bag packed','No new medicine without doctor','Monitor every 1 hour']; default: return ['🚑 ER if lips turn blue','No exercise at all','Avoid very hot showers','Consider relocating temporarily']; } }
  List<String> _getAllergyGoodRec(String g) { if(['toddler','child'].contains(g)) return ['✅ Outdoor play safe but avoid grassy fields','🧴 Child-safe moisturizer','👕 Full sleeves','💧 Plenty of water']; return ['✅ Outdoor activities fine','💊 Carry antihistamine','🕶️ Sunglasses for dust','🧴 Moisturizer for skin allergies']; }
  List<String> _getAllergyGoodPrec(String g) { if(['toddler','child'].contains(g)) return ['Shower after outdoor play','Wash hands/face immediately','Avoid stuffed toys']; return ['Shower after returning','Change clothes','Don\'t dry clothes outside']; }
  List<String> _getAllergySatRec(String g) { if(['toddler','child'].contains(g)) return ['⚠️ Limit outdoor to 20 min','💊 Antihistamine before going out','😷 Child mask in dusty areas','🧴 Heavy moisturizer','🪟 Close bedroom windows']; if(['senior','elderly'].contains(g)) return ['⚠️ Avoid gardens/parks','💊 Morning antihistamine','👁️ Lubricating eye drops','🪟 Keep house sealed','💧 Warm turmeric water']; return ['⚠️ Limit open/grassy areas','💊 Antihistamine before commute','🕶️ Wraparound sunglasses','😷 Mask in traffic','🧴 Barrier cream']; }
  List<String> _getAllergySatPrec(String g) { if(['toddler','child'].contains(g)) return ['Don\'t let child rub eyes','Avoid freshly cut grass','Wash hair before bedtime']; if(['senior','elderly'].contains(g)) return ['Avoid morning dew','Use HEPA filter vacuum','No strong chemicals']; return ['Shower immediately after','Don\'t touch face','Clean AC filters']; }
  List<String> _getAllergyModRec(String g) { if(['toddler','child'].contains(g)) return ['🏠 Strictly indoors','💊 Antihistamine + nasal spray','👁️ Cold compress on eyes','🧴 Moisturizer every 3 hrs','🫧 Humidifier in room']; return ['🏠 Stay indoors','💊 Check allergy meds','👁️ Antihistamine eye drops','🧴 Calamine for rashes','😷 N95 if must go out','🪟 Seal windows/doors']; }
  List<String> _getAllergyModPrec(String g) { if(['toddler','child'].contains(g)) return ['Watch for hives/swollen face','🚑 Hospital if breathing+rash','No adult allergy medicine for child']; return ['Watch for anaphylaxis','Keep epinephrine accessible','Avoid outside food']; }
  List<String> _getAllergyPoorRec(String g) { return ['🚫 Absolute indoor stay','💊 Max allergy medication','👁️ Eye drops every 4 hrs','🫧 Humidifier running','😷 Mask even indoors','🧴 Full body moisturizer']; }
  List<String> _getAllergyPoorPrec(String g) { return ['🚑 Emergency care for severe swelling','Don\'t open windows','Wet-mop floors','Remove carpets if possible']; }
  List<String> _getMildGoodRec(String g) { if(['toddler','child'].contains(g)) return ['✅ Short outdoor time fine','💧 Warm fluids','🍯 Honey+warm water (age>1)','🧣 Cover nose in breeze']; if(['senior','elderly'].contains(g)) return ['✅ Brief morning sunlight helps','💧 Ginger tea or turmeric milk','🧣 Scarf around throat','💊 Continue medications']; return ['✅ Light outdoor activity fine','💧 Warm water preferred','🍋 Vitamin C foods','😴 Get adequate rest']; }
  List<String> _getMildGoodPrec(String g) { if(['toddler','child'].contains(g)) return ['Don\'t share water bottles','Wash hands frequently']; if(['senior','elderly'].contains(g)) return ['Don\'t skip meals','Gargle with warm salt water']; return ['Avoid cold beverages','Cover mouth when coughing']; }
  List<String> _getMildSatRec(String g) { if(['toddler','child'].contains(g)) return ['🏠 Keep child home','💧 Warm soup/dal water','🧣 Keep chest warm','💊 Cough syrup on time','😴 Afternoon nap']; return ['🏠 Rest at home','😷 Mask to protect throat','💧 Warm water hourly','💊 Cold medicine on schedule','🍵 Herbal tea with honey']; }
  List<String> _getMildSatPrec(String g) { if(['toddler','child'].contains(g)) return ['No school if fever','Watch for ear pain']; return ['Pollution slows recovery','See doctor if cough >5 days','Avoid dairy if increases mucus']; }
  List<String> _getMildModRec(String g) { if(['toddler','child'].contains(g)) return ['🏠 STRICTLY indoors','💊 All medicines on time','🫧 Steam vaporizer','💧 Warm fluids every 30 min','🪟 Windows sealed','🧸 Indoor activities']; return ['🏠 Stay home','😷 Mask for short trips','💊 Continue medications','🫧 Steam 2-3 times/day','💧 3+ liters warm water','🍯 Honey+ginger for throat']; }
  List<String> _getMildModPrec(String g) { if(['toddler','child'].contains(g)) return ['🏥 Doctor if fever >100.4°F','Watch rapid breathing','Don\'t self-medicate']; return ['See doctor if symptoms worsen','Watch for yellow mucus','Avoid self-medicating antibiotics']; }
  List<String> _getHealthyGoodRec(String g) { switch(g){ case 'toddler': return ['✅ Perfect for park!','🧒 Play freely','☀️ Sunscreen','💧 Water and snacks']; case 'child': return ['✅ Great for outdoor games!','⚽ Sports/cycling safe','💧 Water every 20 min','☀️ Wear cap']; case 'teen': return ['✅ Perfect for sports','🏃 Running/cycling/swimming','💧 Stay hydrated','🎒 Enjoy outdoors']; case 'senior': return ['✅ Excellent for walk','🧘 Outdoor yoga safe','💧 Carry water','🌳 Visit a park']; case 'elderly': return ['✅ Short outdoor time good','🚶 Gentle walking','☀️ 15 min sunlight','💧 Sip water']; default: return ['✅ Enjoy any outdoor activity!','🏃 Jogging/gym safe','🪟 Open windows','💧 Great day to be active']; } }
  List<String> _getHealthySatRec(String g) { switch(g){ case 'toddler': case 'child': return ['✅ Outdoor play fine, limit 1 hr','💧 Keep hydrated','🏠 Indoor if dusty','😷 No mask needed']; case 'senior': case 'elderly': return ['⚠️ Walk morning only 6-8 AM','💧 Warm water','🏠 Indoor in afternoon','🧘 Indoor yoga']; default: return ['✅ Normal activities fine','🏃 Moderate outdoor exercise okay','💧 Stay hydrated','⚠️ Avoid peak traffic for jogging']; } }
  List<String> _getHealthySatPrec(String g) { switch(g){ case 'toddler': case 'child': return ['Avoid roads/construction','Wash hands/face after']; case 'senior': case 'elderly': return ['Don\'t overexert','Come inside if hazy']; default: return ['Reduce outdoor exercise if stuffy','Avoid main roads']; } }
  List<String> _getHealthyModRec(String g) { switch(g){ case 'toddler': return ['🏠 Keep indoors','🎨 Indoor play','🪟 Close windows','💧 Extra fluids']; case 'child': return ['🏠 No outdoor games','📚 Indoor only','😷 Mask to school','💧 More water']; case 'teen': return ['⚠️ Skip outdoor sports','😷 Mask for commute','🏠 Study indoors','🏋️ Indoor exercise']; case 'senior': case 'elderly': return ['🏠 Stay indoors all day','🪟 Seal windows','💧 Warm fluids','📞 Stay connected']; default: return ['😷 Mask during commute','🏠 Work from home','🏋️ Indoor gym only','🪟 Windows closed','💧 Increase water']; } }
  List<String> _getHealthyModPrec(String g) { switch(g){ case 'toddler': case 'child': return ['Watch for new cough/eye rubbing','No mosquito coils']; case 'senior': case 'elderly': return ['Monitor for breathing difficulty','Don\'t skip meds','Order delivery']; default: return ['Avoid roadside food stalls','Don\'t jog outdoors','Monitor for headache']; } }
  List<String> _getHealthyPoorRec(String g) { switch(g){ case 'toddler': case 'child': return ['🚫 MUST stay indoors','🫁 Air purifier','😷 Mask if no purifier','🪟 Seal gaps','💧 Warm water+nutrition']; case 'senior': case 'elderly': return ['🚫 Do NOT go outside','🏠 Cleanest room','😷 Mask moving around','💧 Warm water every 30 min','📞 Doctor\'s number handy']; default: return ['🚫 Avoid ALL outdoor','😷 N95 if must go out','🏠 Windows sealed','🫁 Air purifier high','💧 Plenty of fluids']; } }
  List<String> _getSevereRec(String g, bool resp, bool heart, bool allergy) { List<String> r=['🚫 NOBODY outside','🏠 Sealed room','😷 N95 even indoors','🫁 Air purifier MAX','💧 Warm water every 30 min','🪟 Seal gaps with wet towels']; if(resp){r.insert(0,'🚨 ASTHMA/COPD: Nebulizer every 4 hrs!'); r.add('💊 ALL emergency respiratory meds');} if(heart){r.insert(0,'❤️ HEART: Check BP every 2 hrs!'); r.add('💊 Heart meds strictly on schedule');} if(allergy){r.add('👁️ Eye drops every 4 hrs'); r.add('🧴 Full body moisturizer');} if(['toddler','child'].contains(g)) r.insert(0,'👶 CHILDREN: Safest sealed room!'); if(['senior','elderly'].contains(g)) r.insert(0,'👴 ELDERLY: Someone must stay with you!'); return r; }
  List<String> _getSeverePrec(String g, bool resp, bool heart, bool allergy) { List<String> p=['🚑 Call ambulance if ANY breathing difficulty','No exercise even indoors','No gas cooking','No incense/candles/coils','Emergency bag packed']; if(resp){p.add('ASTHMA: ER if inhaler doesn\'t help in 15 min'); p.add('Consider temporary relocation');} if(heart){p.add('HEART: ER if chest pain/arm numbness'); p.add('Avoid hot showers');} if(['toddler','child'].contains(g)) p.add('CHILD: Hospital if blue lips/fast breathing'); if(['senior','elderly'].contains(g)){p.add('ELDERLY: Check every 1 hour'); p.add('Keep oxygen concentrator ready');} return p; }

  @override
  void dispose() { _ageController.dispose(); super.dispose(); }
}