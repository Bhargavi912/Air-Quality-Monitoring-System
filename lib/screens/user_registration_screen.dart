import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import 'home_screen.dart';

class UserRegistrationScreen extends StatefulWidget {
  final bool isEditing;
  final UserProfile? existingProfile;

  const UserRegistrationScreen({
    super.key,
    this.isEditing = false,
    this.existingProfile,
  });

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  int _step = 0; // 0=Name, 1=Age+Gender, 2=Health, 3=Emergency+Review
  final _nameController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _otherConditionController = TextEditingController(); // Controller for 'Other'
  
  int _age = 25;
  String _gender = 'Female';
  final Set<String> _selectedConditions = {'none'};

  final List<String> _genders = ['Male', 'Female', 'Other'];

  final List<Map<String, dynamic>> _conditionOptions = [
    {'key': 'none', 'label': 'None (Healthy)', 'icon': Icons.check_circle, 'color': Colors.green},
    {'key': 'asthma', 'label': 'Asthma', 'icon': Icons.air, 'color': Colors.red},
    {'key': 'sinusitis', 'label': 'Sinusitis', 'icon': Icons.face, 'color': Colors.orange},
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
    // NEW OPTION ADDED HERE
    {'key': 'other', 'label': 'Other (Specify)', 'icon': Icons.add_circle, 'color': Colors.blueGrey},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      final p = widget.existingProfile!;
      _nameController.text = p.name;
      _age = p.age;
      _gender = p.gender;
      _emergencyController.text = p.emergencyContact;
      _selectedConditions.clear();
      if (p.healthConditions.isEmpty || p.healthConditions.contains('none')) {
        _selectedConditions.add('none');
      } else {
        _selectedConditions.addAll(p.healthConditions);
      }
    }
  }

  void _toggleCondition(String key) {
    setState(() {
      if (key == 'none') {
        _selectedConditions.clear();
        _selectedConditions.add('none');
        _otherConditionController.clear();
      } else {
        _selectedConditions.remove('none');
        if (_selectedConditions.contains(key)) {
          _selectedConditions.remove(key);
          if (key == 'other') {
            _otherConditionController.clear();
          }
          if (_selectedConditions.isEmpty) _selectedConditions.add('none');
        } else {
          _selectedConditions.add(key);
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    final profile = UserProfile(
      name: _nameController.text.trim(),
      age: _age,
      gender: _gender,
      healthConditions: _selectedConditions.toList(),
      emergencyContact: _emergencyController.text.trim(),
    );
    await UserProfile.save(profile);

    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  String _getAgeGroup(int age) {
    if (age <= 5) return 'Toddler';
    if (age <= 12) return 'Child';
    if (age <= 17) return 'Teen';
    if (age <= 45) return 'Adult';
    if (age <= 60) return 'Middle Aged';
    if (age <= 75) return 'Senior';
    return 'Elderly';
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
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    if (_step > 0 || widget.isEditing)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () {
                          if (_step > 0) {
                            setState(() => _step--);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    Text(
                      widget.isEditing ? 'Edit Profile' : 'Create Profile',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                child: Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? const Color(0xFF26DE81) : Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Text('Step ${_step + 1} of 4', style: const TextStyle(fontSize: 12, color: Colors.white54)),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _step == 0 ? _buildNameStep()
                      : _step == 1 ? _buildAgeGenderStep()
                      : _step == 2 ? _buildHealthStep()
                      : _buildReviewStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // STEP 1: NAME
  // ═══════════════════════════════════════════════
  Widget _buildNameStep() {
    return SingleChildScrollView(
      key: const ValueKey('step_name'),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF26DE81), Color(0xFF20BF6B)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF26DE81).withAlpha(80), blurRadius: 20)],
            ),
            child: const Icon(Icons.person_add_rounded, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            widget.isEditing ? 'Update Your Name' : 'Welcome to BreathSafe! 🌿',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Let\'s set up your profile for personalized\nair quality health advice',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white54, height: 1.4),
          ),
          const SizedBox(height: 40),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Your Name', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 18, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
              prefixIcon: Icon(Icons.person_rounded, color: Colors.white.withAlpha(100)),
              filled: true,
              fillColor: Colors.white.withAlpha(15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF26DE81), width: 2),
              ),
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _nextStep(),
          ),
          const SizedBox(height: 30),
          _nextButton('Next'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // STEP 2: AGE + GENDER
  // ═══════════════════════════════════════════════
  Widget _buildAgeGenderStep() {
    return SingleChildScrollView(
      key: const ValueKey('step_age'),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4B7BEC), Color(0xFF3867D6)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF4B7BEC).withAlpha(80), blurRadius: 20)],
            ),
            child: const Icon(Icons.cake_rounded, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('Your Age & Gender', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Used for age-specific health advisory', style: TextStyle(fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 30),

          // Age
          const Align(alignment: Alignment.centerLeft, child: Text('Age', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.white70, size: 28),
                  onPressed: () { if (_age > 1) setState(() => _age--); },
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('$_age', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(_getAgeGroup(_age), style: const TextStyle(fontSize: 13, color: Color(0xFF26DE81), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.white70, size: 28),
                  onPressed: () { if (_age < 120) setState(() => _age++); },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: const SliderThemeData(
              activeTrackColor: Color(0xFF26DE81),
              thumbColor: Color(0xFF26DE81),
              inactiveTrackColor: Colors.white12,
            ),
            child: Slider(
              value: _age.toDouble(),
              min: 1, max: 120,
              divisions: 119,
              label: '$_age',
              onChanged: (v) => setState(() => _age = v.round()),
            ),
          ),

          const SizedBox(height: 20),

          // Gender
          const Align(alignment: Alignment.centerLeft, child: Text('Gender', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Row(
            children: _genders.map((g) {
              final sel = _gender == g;
              final icon = g == 'Male' ? Icons.male : g == 'Female' ? Icons.female : Icons.transgender;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF4B7BEC).withAlpha(40) : Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? const Color(0xFF4B7BEC) : Colors.white.withAlpha(30), width: sel ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Icon(icon, color: sel ? const Color(0xFF4B7BEC) : Colors.white54, size: 28),
                        const SizedBox(height: 4),
                        Text(g, style: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),
          _nextButton('Next'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // STEP 3: HEALTH CONDITIONS
  // ═══════════════════════════════════════════════
  Widget _buildHealthStep() {
    return SingleChildScrollView(
      key: const ValueKey('step_health'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFFF6B6B).withAlpha(80), blurRadius: 20)],
            ),
            child: const Icon(Icons.medical_services_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text('Health Conditions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Select all that apply. Choose "None" if healthy.', style: TextStyle(fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 20),

          ...List.generate(_conditionOptions.length, (i) {
            final c = _conditionOptions[i];
            final key = c['key'] as String;
            final sel = _selectedConditions.contains(key);
            final color = c['color'] as Color;

            return GestureDetector(
              onTap: () => _toggleCondition(key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? color.withAlpha(30) : Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? color : Colors.white.withAlpha(20), width: sel ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: sel ? color.withAlpha(40) : Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(c['icon'] as IconData, color: sel ? color : Colors.white38, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(c['label'] as String, style: TextStyle(
                        fontSize: 14, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? Colors.white : Colors.white60,
                      )),
                    ),
                    if (sel)
                      Container(width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 16))
                    else
                      Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2))),
                  ],
                ),
              ),
            );
          }),

          // NEW: Text field that appears when 'Other' is selected
          if (_selectedConditions.contains('other'))
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: TextField(
                controller: _otherConditionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Please describe your condition',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'e.g., Diabetes, Migraines',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                  prefixIcon: const Icon(Icons.edit_note, color: Colors.blueGrey),
                  filled: true,
                  fillColor: Colors.white.withAlpha(15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), 
                    borderSide: BorderSide.none
                  ),
                ),
              ),
            ),

          if (!_selectedConditions.contains('none'))
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(10)),
              child: Text('${_selectedConditions.length} condition(s) selected', style: const TextStyle(color: Colors.orange, fontSize: 13)),
            ),

          const SizedBox(height: 20),
          _nextButton('Next'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // STEP 4: REVIEW & SAVE
  // ═══════════════════════════════════════════════
  Widget _buildReviewStep() {
    final condLabels = _conditionOptions
        .where((c) => _selectedConditions.contains(c['key']) && c['key'] != 'none')
        .map((c) {
          if (c['key'] == 'other') {
            final customText = _otherConditionController.text.trim();
            return customText.isNotEmpty ? 'Other: $customText' : 'Other';
          }
          return c['label'] as String;
        })
        .toList();
        
    final hasNone = _selectedConditions.contains('none');

    final tempProfile = UserProfile(
      name: _nameController.text.trim(),
      age: _age,
      gender: _gender,
      healthConditions: _selectedConditions.toList(),
    );

    return SingleChildScrollView(
      key: const ValueKey('step_review'),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Avatar
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withAlpha(80), blurRadius: 20)],
            ),
            child: Center(
              child: Text(
                _nameController.text.trim().isNotEmpty ? _nameController.text.trim()[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Review Your Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),

          // Profile Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Column(
              children: [
                _reviewRow('👤', 'Name', _nameController.text.trim().isEmpty ? 'Not set' : _nameController.text.trim()),
                _reviewRow('🎂', 'Age', '$_age years (${_getAgeGroup(_age)})'),
                _reviewRow('⚧', 'Gender', _gender),
                _reviewRow(tempProfile.riskEmoji, 'Risk Level', tempProfile.riskLevel),
                const Divider(color: Colors.white12, height: 24),
                const Align(alignment: Alignment.centerLeft, child: Text('🩺 Health Conditions', style: TextStyle(color: Colors.white70, fontSize: 13))),
                const SizedBox(height: 8),
                if (hasNone)
                  const Text('✅ No health conditions — Healthy!', style: TextStyle(color: Colors.green, fontSize: 14))
                else
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: condLabels.map((l) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                      child: Text(l, style: const TextStyle(fontSize: 12, color: Colors.orange)),
                    )).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Emergency Contact (optional)
          const Align(alignment: Alignment.centerLeft, child: Text('Emergency Contact (Optional)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          TextField(
            controller: _emergencyController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Phone number',
              hintStyle: TextStyle(color: Colors.white.withAlpha(40)),
              prefixIcon: Icon(Icons.phone, color: Colors.white.withAlpha(60)),
              filled: true,
              fillColor: Colors.white.withAlpha(10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 30),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your name'), backgroundColor: Colors.orange),
                  );
                  setState(() => _step = 0);
                  return;
                }
                _saveProfile();
              },
              icon: Icon(widget.isEditing ? Icons.save_rounded : Icons.check_circle_rounded, size: 22),
              label: Text(
                widget.isEditing ? 'Save Changes' : 'Create Profile & Start',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26DE81),
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: const Color(0xFF26DE81).withAlpha(100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _reviewRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text('$label:', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_step == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    // Check if 'Other' is selected but left blank
    if (_step == 2 && _selectedConditions.contains('other') && _otherConditionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your condition in the "Other" text box'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_step < 3) setState(() => _step++);
  }

  Widget _nextButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF26DE81),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emergencyController.dispose();
    _otherConditionController.dispose();
    super.dispose();
  }
}