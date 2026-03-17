import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/air_quality_provider.dart';

class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({super.key});

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  int _page = 0; // 0=Log, 1=History, 2=Insights
  List<Map<String, dynamic>> _entries = [];
  bool _loaded = false;

  final List<Map<String, dynamic>> _symptomList = [
    {'key': 'headache', 'label': 'Headache', 'icon': Icons.psychology, 'color': Colors.indigo},
    {'key': 'cough', 'label': 'Cough', 'icon': Icons.record_voice_over, 'color': Colors.orange},
    {'key': 'eye_irritation', 'label': 'Eye Irritation', 'icon': Icons.remove_red_eye, 'color': Colors.teal},
    {'key': 'throat', 'label': 'Throat Irritation', 'icon': Icons.mic, 'color': Colors.brown},
    {'key': 'breathing', 'label': 'Breathing Difficulty', 'icon': Icons.air, 'color': Colors.red},
    {'key': 'sneezing', 'label': 'Sneezing / Runny Nose', 'icon': Icons.face, 'color': Colors.blue},
    {'key': 'wheezing', 'label': 'Wheezing', 'icon': Icons.healing, 'color': Colors.deepOrange},
    {'key': 'skin_rash', 'label': 'Skin Rash / Itching', 'icon': Icons.back_hand, 'color': Colors.pink},
    {'key': 'fatigue', 'label': 'Fatigue / Tiredness', 'icon': Icons.battery_1_bar, 'color': Colors.grey},
    {'key': 'nausea', 'label': 'Nausea / Dizziness', 'icon': Icons.sick, 'color': Colors.purple},
    {'key': 'chest_pain', 'label': 'Chest Tightness', 'icon': Icons.favorite, 'color': Colors.redAccent},
    {'key': 'no_symptoms', 'label': 'No Symptoms (Feeling Good!)', 'icon': Icons.check_circle, 'color': Colors.green},
  ];

  final Map<String, int> _selectedSymptoms = {};
  String _notes = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('symptom_entries');
    if (data != null) {
      _entries = List<Map<String, dynamic>>.from(json.decode(data));
    }
    setState(() => _loaded = true);
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('symptom_entries', json.encode(_entries));
  }

  void _toggleSymptom(String key) {
    setState(() {
      if (key == 'no_symptoms') {
        _selectedSymptoms.clear();
        _selectedSymptoms['no_symptoms'] = 0;
      } else {
        _selectedSymptoms.remove('no_symptoms');
        if (_selectedSymptoms.containsKey(key)) {
          _selectedSymptoms.remove(key);
        } else {
          _selectedSymptoms[key] = 5; // default severity
        }
      }
    });
  }

  void _setSeverity(String key, int val) {
    setState(() => _selectedSymptoms[key] = val);
  }

  void _saveEntry() {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom or "No Symptoms"'), backgroundColor: Colors.orange),
      );
      return;
    }

    final provider = context.read<AirQualityProvider>();
    final aqi = provider.currentAqi?.standardAqi ?? 0;
    final pm25 = provider.currentAqi?.pm25 ?? 0.0;
    final location = provider.locationName ?? 'Unknown';

    final entry = {
      'date': DateTime.now().toIso8601String(),
      'aqi': aqi,
      'pm25': pm25,
      'location': location,
      'symptoms': Map<String, int>.from(_selectedSymptoms),
      'notes': _notes,
      'aqiLevel': provider.currentAqi?.level ?? 'Unknown',
    };

    _entries.insert(0, entry);
    _saveEntries();

    setState(() {
      _selectedSymptoms.clear();
      _notes = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Text('Logged! AQI: $aqi • ${_entries.length} total entries'),
        ]),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteEntry(int index) async {
    setState(() => _entries.removeAt(index));
    await _saveEntries();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will delete all symptom entries. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _entries.clear());
      await _saveEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _page == 0 ? '📝 Log Symptoms' : _page == 1 ? '📋 History' : '📊 Insights',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_page > 0) {
              setState(() => _page = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_page == 0 && _entries.isNotEmpty)
            Badge(
              label: Text('${_entries.length}'),
              child: IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => setState(() => _page = 1),
                tooltip: 'History',
              ),
            ),
          if (_page == 0 && _entries.length >= 3)
            IconButton(
              icon: const Icon(Icons.insights_rounded),
              onPressed: () => setState(() => _page = 2),
              tooltip: 'Insights',
            ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _page == 0
                  ? _buildLogPage()
                  : _page == 1
                      ? _buildHistoryPage()
                      : _buildInsightsPage(),
            ),
    );
  }

  // ═══════════════════════════════════════════════
  // PAGE 1: LOG SYMPTOMS
  // ═══════════════════════════════════════════════
  Widget _buildLogPage() {
    final provider = context.watch<AirQualityProvider>();
    final aqi = provider.currentAqi?.standardAqi ?? 0;
    final pm25 = provider.currentAqi?.pm25 ?? 0.0;
    final location = provider.locationName ?? 'Getting location...';
    final level = provider.currentAqi?.level ?? 'Loading...';

    return SingleChildScrollView(
      key: const ValueKey('log'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AQI Auto-captured badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _getGradient(aqi)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$aqi', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Auto-captured AQI', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(level, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('📍 $location • PM2.5: ${pm25.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.auto_fix_high, color: Colors.white54, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('AQI is recorded automatically when you save', style: TextStyle(fontSize: 11, color: Colors.grey))),

          const SizedBox(height: 20),
          const Text('How are you feeling right now?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Select all symptoms you\'re experiencing', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),

          // Symptom list
          ...List.generate(_symptomList.length, (i) {
            final s = _symptomList[i];
            final key = s['key'] as String;
            final sel = _selectedSymptoms.containsKey(key);
            final color = s['color'] as Color;
            final severity = _selectedSymptoms[key] ?? 5;
            final isNoSymptom = key == 'no_symptoms';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: sel ? color.withAlpha(15) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? color : Colors.grey.shade200, width: sel ? 2 : 1),
                boxShadow: sel ? [BoxShadow(color: color.withAlpha(20), blurRadius: 8)] : null,
              ),
              child: Column(
                children: [
                  // Symptom row
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _toggleSymptom(key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: sel ? color.withAlpha(30) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(s['icon'] as IconData, color: sel ? color : Colors.grey.shade400, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s['label'] as String,
                              style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? color : Colors.black87),
                            ),
                          ),
                          if (sel && !isNoSymptom)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                              child: Text('$severity/10', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                            ),
                          const SizedBox(width: 6),
                          sel
                              ? Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                )
                              : Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)),
                                ),
                        ],
                      ),
                    ),
                  ),

                  // Severity slider (only if selected & not "no symptoms")
                  if (sel && !isNoSymptom)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Row(
                        children: [
                          const Text('Mild', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: color,
                                thumbColor: color,
                                inactiveTrackColor: color.withAlpha(30),
                                overlayColor: color.withAlpha(20),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: severity.toDouble(),
                                min: 1, max: 10,
                                divisions: 9,
                                label: '$severity',
                                onChanged: (v) => _setSeverity(key, v.round()),
                              ),
                            ),
                          ),
                          const Text('Severe', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Notes
          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Any additional notes... (optional)',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.note_add_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (v) => _notes = v,
          ),

          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save_rounded, size: 22),
              label: const Text('Save Symptom Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Quick links
          Row(
            children: [
              if (_entries.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _page = 1),
                    icon: const Icon(Icons.history, size: 18),
                    label: Text('History (${_entries.length})', style: const TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              if (_entries.isNotEmpty) const SizedBox(width: 10),
              if (_entries.length >= 3)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _page = 2),
                    icon: const Icon(Icons.insights, size: 18),
                    label: const Text('View Insights', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // PAGE 2: HISTORY
  // ═══════════════════════════════════════════════
  Widget _buildHistoryPage() {
    if (_entries.isEmpty) {
      return const Center(
        key: ValueKey('history_empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('No entries yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text('Log your first symptoms to see history', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('history'),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF6C5CE7).withAlpha(15),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              Text('${_entries.length} Entries', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_entries.length >= 3)
                TextButton.icon(
                  onPressed: () => setState(() => _page = 2),
                  icon: const Icon(Icons.insights, size: 16),
                  label: const Text('Insights', style: TextStyle(fontSize: 12)),
                ),
              TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
                label: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.red)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _entries.length,
            itemBuilder: (_, i) => _buildHistoryCard(i),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(int index) {
    final e = _entries[index];
    final date = DateTime.tryParse(e['date'] ?? '') ?? DateTime.now();
    final aqi = e['aqi'] as int? ?? 0;
    final symptoms = Map<String, dynamic>.from(e['symptoms'] ?? {});
    final notes = e['notes'] as String? ?? '';
    final location = e['location'] as String? ?? '';

    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';
    final timeStr = '${date.hour > 12 ? date.hour - 12 : date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';

    return Dismissible(
      key: ValueKey(e['date']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => _deleteEntry(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + AQI
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text('$dateStr • $timeStr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _getAqiColor(aqi).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                  child: Text('AQI $aqi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getAqiColor(aqi))),
                ),
              ],
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('📍 $location', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            const SizedBox(height: 10),
            // Symptoms
            Wrap(
              spacing: 6, runSpacing: 6,
              children: symptoms.entries.map((entry) {
                final info = _symptomList.firstWhere((s) => s['key'] == entry.key, orElse: () => {'label': entry.key, 'color': Colors.grey});
                final sev = entry.value is int ? entry.value as int : 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (info['color'] as Color).withAlpha(50)),
                  ),
                  child: Text(
                    entry.key == 'no_symptoms' ? '✅ No Symptoms' : '${info['label']} ($sev/10)',
                    style: TextStyle(fontSize: 11, color: info['color'] as Color, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('📝 $notes', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // PAGE 3: INSIGHTS & CORRELATION
  // ═══════════════════════════════════════════════
  Widget _buildInsightsPage() {
    if (_entries.length < 3) {
      return Center(
        key: const ValueKey('insights_empty'),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.insights, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Need more data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Log at least 3 entries to see insights.\nYou have ${_entries.length} so far.',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Calculate stats
    final symptomStats = _calculateSymptomStats();
    final correlations = _calculateCorrelations();
    final avgAqi = _entries.map((e) => e['aqi'] as int).reduce((a, b) => a + b) / _entries.length;
    final symptomDays = _entries.where((e) => !(e['symptoms'] as Map).containsKey('no_symptoms')).length;
    final goodDays = _entries.where((e) => (e['symptoms'] as Map).containsKey('no_symptoms')).length;

    return SingleChildScrollView(
      key: const ValueKey('insights'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              _summaryCard('📊', '${_entries.length}', 'Total\nEntries', Colors.blue),
              const SizedBox(width: 10),
              _summaryCard('😷', '$symptomDays', 'Symptom\nDays', Colors.orange),
              const SizedBox(width: 10),
              _summaryCard('😊', '$goodDays', 'Good\nDays', Colors.green),
              const SizedBox(width: 10),
              _summaryCard('🌍', '${avgAqi.round()}', 'Avg\nAQI', _getAqiColor(avgAqi.round())),
            ],
          ),
          const SizedBox(height: 24),

          // Most Common Symptoms
          const Text('🔍 Most Common Symptoms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (symptomStats.isEmpty)
            const Text('No symptoms recorded yet!', style: TextStyle(color: Colors.grey))
          else
            ...symptomStats.take(6).map((stat) {
              final info = _symptomList.firstWhere((s) => s['key'] == stat['key'], orElse: () => {'label': stat['key'], 'color': Colors.grey});
              final pct = (stat['count'] as int) / _entries.length * 100;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(info['icon'] as IconData? ?? Icons.circle, size: 18, color: info['color'] as Color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(info['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                        Text('${stat['count']}x', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(width: 6),
                        Text('(${pct.round()}%)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 6,
                        backgroundColor: (info['color'] as Color).withAlpha(20),
                        valueColor: AlwaysStoppedAnimation(info['color'] as Color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg severity: ${(stat['avgSeverity'] as double).toStringAsFixed(1)}/10 • Avg AQI when reported: ${(stat['avgAqi'] as double).round()}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // Correlation Insights
          const Text('📈 Pollution-Health Correlation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('How your symptoms relate to air quality', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),

          if (correlations.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Text('Need more data with symptoms to find correlations.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...correlations.map((c) {
              final color = c['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withAlpha(10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(c['icon'] as IconData, size: 20, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(c['insight'] as String, style: const TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 14)),
                          Expanded(child: Text(c['tip'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // AQI Distribution
          const Text('📊 AQI When Symptoms Occurred', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildAqiDistribution(),

          const SizedBox(height: 24),

          // Personal Threshold
          _buildPersonalThreshold(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAqiDistribution() {
    int good = 0, sat = 0, mod = 0, poor = 0, vPoor = 0, severe = 0;
    for (final e in _entries) {
      if ((e['symptoms'] as Map).containsKey('no_symptoms')) continue;
      final aqi = e['aqi'] as int;
      if (aqi <= 50) good++;
      else if (aqi <= 100) sat++;
      else if (aqi <= 200) mod++;
      else if (aqi <= 300) poor++;
      else if (aqi <= 400) vPoor++;
      else severe++;
    }
    final total = good + sat + mod + poor + vPoor + severe;
    if (total == 0) return const Text('No symptom days yet', style: TextStyle(color: Colors.grey));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          _distBar('Good (0-50)', good, total, const Color(0xFF4CAF50)),
          _distBar('Satisfactory (51-100)', sat, total, const Color(0xFFC6CC00)),
          _distBar('Moderate (101-200)', mod, total, const Color(0xFFFF9800)),
          _distBar('Poor (201-300)', poor, total, const Color(0xFFF44336)),
          _distBar('Very Poor (301-400)', vPoor, total, const Color(0xFF9C27B0)),
          _distBar('Severe (400+)', severe, total, const Color(0xFF880000)),
        ],
      ),
    );
  }

  Widget _distBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: pct / 100, minHeight: 8, backgroundColor: color.withAlpha(20), valueColor: AlwaysStoppedAnimation(color)),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count (${pct.round()}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPersonalThreshold() {
    final symptomEntries = _entries.where((e) => !(e['symptoms'] as Map).containsKey('no_symptoms')).toList();
    final noSymptomEntries = _entries.where((e) => (e['symptoms'] as Map).containsKey('no_symptoms')).toList();

    if (symptomEntries.isEmpty || noSymptomEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final avgSymptomAqi = symptomEntries.map((e) => e['aqi'] as int).reduce((a, b) => a + b) / symptomEntries.length;
    final avgGoodAqi = noSymptomEntries.map((e) => e['aqi'] as int).reduce((a, b) => a + b) / noSymptomEntries.length;
    final threshold = ((avgSymptomAqi + avgGoodAqi) / 2).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🎯 Your Personal AQI Threshold', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white.withAlpha(30), shape: BoxShape.circle),
            child: Center(child: Text('$threshold', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(height: 12),
          Text(
            'When AQI is above $threshold, you tend to experience symptoms.\nBelow $threshold, you usually feel fine.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  const Text('😊 Good Days', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  Text('Avg AQI ${avgGoodAqi.round()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
                Container(width: 1, height: 30, color: Colors.white24),
                Column(children: [
                  const Text('😷 Symptom Days', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  Text('Avg AQI ${avgSymptomAqi.round()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // STATS & CORRELATION CALCULATORS
  // ═══════════════════════════════════════════════

  List<Map<String, dynamic>> _calculateSymptomStats() {
    Map<String, List<Map<String, dynamic>>> symptomData = {};

    for (final e in _entries) {
      final symptoms = Map<String, dynamic>.from(e['symptoms'] ?? {});
      final aqi = e['aqi'] as int? ?? 0;
      for (final entry in symptoms.entries) {
        if (entry.key == 'no_symptoms') continue;
        symptomData.putIfAbsent(entry.key, () => []);
        symptomData[entry.key]!.add({'severity': entry.value is int ? entry.value : 0, 'aqi': aqi});
      }
    }

    List<Map<String, dynamic>> stats = [];
    for (final entry in symptomData.entries) {
      final data = entry.value;
      final avgSev = data.map((d) => d['severity'] as int).reduce((a, b) => a + b) / data.length;
      final avgAqi = data.map((d) => d['aqi'] as int).reduce((a, b) => a + b) / data.length;
      stats.add({'key': entry.key, 'count': data.length, 'avgSeverity': avgSev, 'avgAqi': avgAqi});
    }

    stats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return stats;
  }

  List<Map<String, dynamic>> _calculateCorrelations() {
    List<Map<String, dynamic>> insights = [];
    final stats = _calculateSymptomStats();
    final noSymptomEntries = _entries.where((e) => (e['symptoms'] as Map).containsKey('no_symptoms')).toList();

    double avgGoodAqi = 0;
    if (noSymptomEntries.isNotEmpty) {
      avgGoodAqi = noSymptomEntries.map((e) => e['aqi'] as int).reduce((a, b) => a + b) / noSymptomEntries.length;
    }

    for (final stat in stats.take(4)) {
      final key = stat['key'] as String;
      final avgAqi = stat['avgAqi'] as double;
      final avgSev = stat['avgSeverity'] as double;
      final count = stat['count'] as int;
      final info = _symptomList.firstWhere((s) => s['key'] == key, orElse: () => {'label': key, 'icon': Icons.circle, 'color': Colors.grey});

      String insight;
      String tip;

      if (noSymptomEntries.isNotEmpty && avgAqi > avgGoodAqi + 20) {
        final diff = ((avgAqi - avgGoodAqi) / avgGoodAqi * 100).round();
        insight = 'Your ${(info['label'] as String).toLowerCase()} occurs when AQI is ~${avgAqi.round()}, '
            'which is $diff% higher than your symptom-free days (AQI ~${avgGoodAqi.round()}).';
        tip = 'Avoid outdoor exposure when AQI exceeds ${(avgGoodAqi + (avgAqi - avgGoodAqi) * 0.5).round()} to reduce ${(info['label'] as String).toLowerCase()}.';
      } else {
        insight = 'You reported ${(info['label'] as String).toLowerCase()} $count times with average severity ${avgSev.toStringAsFixed(1)}/10. '
            'Average AQI during these episodes: ${avgAqi.round()}.';
        tip = 'Track a few more days to discover clearer patterns.';
      }

      insights.add({
        'title': '${info['label']} & Air Quality',
        'icon': info['icon'],
        'color': info['color'],
        'insight': insight,
        'tip': tip,
      });
    }

    // Overall insight
    if (noSymptomEntries.isNotEmpty && stats.isNotEmpty) {
      final symptomEntries = _entries.where((e) => !(e['symptoms'] as Map).containsKey('no_symptoms')).toList();
      if (symptomEntries.isNotEmpty) {
        final avgSymAqi = symptomEntries.map((e) => e['aqi'] as int).reduce((a, b) => a + b) / symptomEntries.length;
        insights.insert(0, {
          'title': '🎯 Overall Pattern',
          'icon': Icons.analytics_rounded,
          'color': const Color(0xFF6C5CE7),
          'insight': 'On days you felt sick, the average AQI was ${avgSymAqi.round()}. '
              'On days you felt good, the average AQI was ${avgGoodAqi.round()}. '
              'That\'s a ${(avgSymAqi - avgGoodAqi).abs().round()} point difference!',
          'tip': 'Your body appears sensitive to AQI above ${((avgSymAqi + avgGoodAqi) / 2).round()}. '
              'Plan outdoor activities when AQI is below this threshold.',
        });
      }
    }

    return insights;
  }

  Widget _summaryCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF4CAF50);
    if (aqi <= 100) return const Color(0xFFC6CC00);
    if (aqi <= 200) return const Color(0xFFFF9800);
    if (aqi <= 300) return const Color(0xFFF44336);
    if (aqi <= 400) return const Color(0xFF9C27B0);
    return const Color(0xFF880000);
  }

  List<Color> _getGradient(int aqi) {
    if (aqi <= 50) return [const Color(0xFF4CAF50), const Color(0xFF81C784)];
    if (aqi <= 100) return [const Color(0xFFC6CC00), const Color(0xFFD4E157)];
    if (aqi <= 200) return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
    if (aqi <= 300) return [const Color(0xFFF44336), const Color(0xFFE57373)];
    if (aqi <= 400) return [const Color(0xFF9C27B0), const Color(0xFFBA68C8)];
    return [const Color(0xFF880000), const Color(0xFFB71C1C)];
  }
}