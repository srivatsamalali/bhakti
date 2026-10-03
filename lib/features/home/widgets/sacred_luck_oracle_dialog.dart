import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/temple_theme.dart';
import '../../../../services/panchanga/panchanga_service.dart';
import '../../../../services/preferences/preferences_service.dart';

class SacredLuckOracleDialog extends StatefulWidget {
  final RashiInfo rashi;
  final String currentLang;

  const SacredLuckOracleDialog({
    super.key,
    required this.rashi,
    required this.currentLang,
  });

  static Future<void> show(BuildContext context, RashiInfo rashi, String currentLang) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SacredLuckOracleDialog(
        rashi: rashi,
        currentLang: currentLang,
      ),
    );
  }

  @override
  State<SacredLuckOracleDialog> createState() => _SacredLuckOracleDialogState();
}

class _SacredLuckOracleDialogState extends State<SacredLuckOracleDialog> with SingleTickerProviderStateMixin {
  DateTime? _selectedDob;
  int _diceNumber = 0;
  bool _isRolling = false;
  bool _hasCalculated = false;
  String _dynamicLiveForecast = '';
  bool _isFetchingLiveApi = false;

  // 5-Minute Cooldown Timer
  int _cooldownSecondsRemaining = 0;
  Timer? _cooldownTimer;

  late AnimationController _diceAnimController;
  late Animation<double> _diceRotationAnim;

  static const int kCooldownDurationSeconds = 300; // 5 minutes (300s)

  @override
  void initState() {
    super.initState();
    _diceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _diceRotationAnim = CurvedAnimation(
      parent: _diceAnimController,
      curve: Curves.easeOutBack,
    );

    _loadStateAndCheckCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _diceAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadStateAndCheckCooldown() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load DOB
    final savedDobStr = prefs.getString('user_dob_oracle');
    if (savedDobStr != null) {
      try {
        _selectedDob = DateTime.parse(savedDobStr);
      } catch (_) {}
    } else {
      _selectedDob = DateTime(2000, 1, 1);
    }

    // 2. Check 5-minute cooldown threshold
    final rashiKey = widget.rashi.id;
    final lastRollTime = prefs.getInt('oracle_last_roll_timestamp_$rashiKey') ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = ((nowMs - lastRollTime) / 1000).floor();

    if (elapsedSeconds < kCooldownDurationSeconds && lastRollTime > 0) {
      _cooldownSecondsRemaining = kCooldownDurationSeconds - elapsedSeconds;
      _diceNumber = prefs.getInt('oracle_last_dice_$rashiKey') ?? 6;
      _dynamicLiveForecast = prefs.getString('oracle_last_forecast_$rashiKey') ?? '';
      _hasCalculated = true;
      _startCooldownTicker();
    } else {
      _cooldownSecondsRemaining = 0;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSecondsRemaining > 0) {
        setState(() {
          _cooldownSecondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _cooldownSecondsRemaining = 0;
        });
      }
    });
  }

  String _formatCooldown(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // --- Numerological Calculations ---
  int _reduceToSingleDigit(int n) {
    while (n > 9) {
      int sum = 0;
      while (n > 0) {
        sum += n % 10;
        n ~/= 10;
      }
      n = sum;
    }
    return n == 0 ? 9 : n;
  }

  int _calculateMulank(DateTime dob) {
    return _reduceToSingleDigit(dob.day);
  }

  int _calculateBhagyank(DateTime dob) {
    return _reduceToSingleDigit(dob.day + dob.month + dob.year);
  }

  String _getPlanetForNumber(int num, String lang) {
    switch (num) {
      case 1: return lang == 'kn' ? 'ಸೂರ್ಯ (Surya ☀️)' : (lang == 'hi' ? 'सूर्य (Surya ☀️)' : 'Sun (Surya ☀️)');
      case 2: return lang == 'kn' ? 'ಚಂದ್ರ (Chandra 🌙)' : (lang == 'hi' ? 'चन्द्र (Chandra 🌙)' : 'Moon (Chandra 🌙)');
      case 3: return lang == 'kn' ? 'ಗುರು (Brihaspati 🌟)' : (lang == 'hi' ? 'गुरु (Brihaspati 🌟)' : 'Jupiter (Guru 🌟)');
      case 4: return lang == 'kn' ? 'ರಾಹು (Rahu ⚡)' : (lang == 'hi' ? 'राहु (Rahu ⚡)' : 'Rahu (Cosmic Radiance ⚡)');
      case 5: return lang == 'kn' ? 'ಬುಧ (Budha 🌿)' : (lang == 'hi' ? 'बुध (Budha 🌿)' : 'Mercury (Budha 🌿)');
      case 6: return lang == 'kn' ? 'ಶುಕ್ರ (Shukra 💎)' : (lang == 'hi' ? 'शुक्र (Shukra 💎)' : 'Venus (Shukra 💎)');
      case 7: return lang == 'kn' ? 'ಕೇತು (Ketu 🪔)' : (lang == 'hi' ? 'केतु (Ketu 🪔)' : 'Ketu (Spiritual Light 🪔)');
      case 8: return lang == 'kn' ? 'ಶನಿ (Shani ⚖️)' : (lang == 'hi' ? 'शनि (Shani ⚖️)' : 'Saturn (Shani ⚖️)');
      case 9:
      default: return lang == 'kn' ? 'ಮಂಗಳ (Kuja 🔥)' : (lang == 'hi' ? 'मंगल (Mangal 🔥)' : 'Mars (Mangala 🔥)');
    }
  }

  // --- Dynamic Live Horoscope Fetching on Device for Rashi ---
  Future<String> _fetchDynamicRashiInsight(String rashiId) async {
    final signMapping = {
      'mesha': 'aries',
      'vrishabha': 'taurus',
      'mithuna': 'gemini',
      'karka': 'cancer',
      'simha': 'leo',
      'kanya': 'virgo',
      'tula': 'libra',
      'vrishchika': 'scorpio',
      'dhanu': 'sagittarius',
      'makara': 'capricorn',
      'kumbha': 'aquarius',
      'meena': 'pisces',
    };

    final sign = signMapping[rashiId] ?? 'aries';

    try {
      final url = Uri.parse('https://horoscope-app-api.vercel.app/api/v1/get-horoscope/daily?sign=$sign&day=TODAY');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final horoscope = json['data']?['horoscope'] as String?;
        if (horoscope != null && horoscope.trim().isNotEmpty) {
          return horoscope.trim();
        }
      }
    } catch (_) {}

    try {
      final altUrl = Uri.parse('https://ohmanda.com/api/horoscope/$sign');
      final res = await http.get(altUrl).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final horoscope = json['horoscope'] as String?;
        if (horoscope != null && horoscope.trim().isNotEmpty) {
          return horoscope.trim();
        }
      }
    } catch (_) {}

    // Rashi-tailored astrological fallback
    return 'Planetary energies align favorably with your ruling deity and celestial house today. Maintain steady focus and positive karma.';
  }

  void _rollDiceAndCalculate() async {
    if (_isRolling || _cooldownSecondsRemaining > 0) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isRolling = true;
      _hasCalculated = false;
      _isFetchingLiveApi = true;
    });

    _diceAnimController.reset();
    _diceAnimController.forward();

    // Fetch dynamic live internet description concurrently
    final liveFuture = _fetchDynamicRashiInsight(widget.rashi.id);

    final random = Random();
    await Future.delayed(const Duration(milliseconds: 750));

    final roll = random.nextInt(6) + 1;
    final liveText = await liveFuture;

    HapticFeedback.heavyImpact();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    final rashiKey = widget.rashi.id;

    // Persist 5-minute activity record
    await prefs.setInt('oracle_last_roll_timestamp_$rashiKey', nowMs);
    await prefs.setInt('oracle_last_dice_$rashiKey', roll);
    await prefs.setString('oracle_last_forecast_$rashiKey', liveText);

    if (mounted) {
      setState(() {
        _diceNumber = roll;
        _dynamicLiveForecast = liveText;
        _isRolling = false;
        _isFetchingLiveApi = false;
        _hasCalculated = true;
        _cooldownSecondsRemaining = kCooldownDurationSeconds;
      });
      _startCooldownTicker();
    }
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: now,
      helpText: widget.currentLang == 'kn' ? 'ಜನ್ಮ ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ' : (widget.currentLang == 'hi' ? 'जन्म तिथि चुनें' : 'Select Date of Birth'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B1D2F),
              onPrimary: Colors.white,
              surface: Color(0xFFFFFDF9),
              onSurface: Color(0xFF3E2723),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_dob_oracle', picked.toIso8601String());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = TempleTheme.fromId(context.read<PreferencesService>().getTempleThemeId());
    final lang = widget.currentLang;
    final now = DateTime.now();

    final mulank = _selectedDob != null ? _calculateMulank(_selectedDob!) : 1;
    final bhagyank = _selectedDob != null ? _calculateBhagyank(_selectedDob!) : 1;
    final todaySeed = _reduceToSingleDigit(now.day + now.month + now.year);

    // Compute Luck Percentage based on Birth Date + Today + Dice Roll + Selected Rashi
    final baseScore = 70;
    final diceBonus = _diceNumber * 4;
    final rashiSeed = widget.rashi.id.length % 5;
    final harmonicBonus = (mulank == todaySeed || bhagyank == todaySeed) ? 8 : (rashiSeed * 2);
    final luckScore = (baseScore + diceBonus + harmonicBonus).clamp(65, 99);

    final title = lang == 'kn'
        ? 'ದೈನಂದಿನ ಅದೃಷ್ಟ ಗಣಕ & ಕವಡೆ ಫಲ 🎲'
        : (lang == 'hi' ? 'दैनिक भाग्य एवं वैदिक पासा फल 🎲' : 'Daily Sacred Luck & Prashna Oracle 🎲');

    final subTitle = lang == 'kn'
        ? '${widget.rashi.name} • ಜನ್ಮದಿನಾಂಕ & ಲೈವ್ ಗ್ರಹಬಲ'
        : (lang == 'hi' ? '${widget.rashi.name} • जन्मतिथि व लाइव ग्रह बल' : '${widget.rashi.name} • Birth Date & Live Astrological Alignment');

    final isCooldownActive = _cooldownSecondsRemaining > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Drag Handle & Close Bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4, left: 20, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF5D4037)),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Dialog Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primaryColor, theme.accentGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.rashi.symbol,
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      Text(
                        subTitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF795548),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE4D7C8)),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 5-Min Cooldown Banner Notice (if active)
                if (isCooldownActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFB300)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFFE65100), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang == 'kn'
                                ? 'ಪವಿತ್ರ ಪ್ರಶ್ನಾವಳಿ ನಿಯಮ: ಮುಂದಿನ ಕವಡೆ ಉರುಳಿಸಲು ${_formatCooldown(_cooldownSecondsRemaining)} ಬಾಕಿ ಇದೆ (5 ನಿಮಿಷಗಳ ಅಂತರ).'
                                : (lang == 'hi'
                                    ? 'वैदिक नियम: अगला पासा फेंकने के लिए ${_formatCooldown(_cooldownSecondsRemaining)} शेष है (5 मिनट अंतराल)।'
                                    : 'Sacred Oracle Rule: Next dice roll available in ${_formatCooldown(_cooldownSecondsRemaining)} (5 min cooldown).'),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBF360C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // STEP 1: Date of Birth Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0D5C7)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: theme.primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            lang == 'kn'
                                ? 'ಹಂತ ೧: ನಿಮ್ಮ ಜನ್ಮ ದಿನಾಂಕ (DOB)'
                                : (lang == 'hi' ? 'चरण १: अपनी जन्म तिथि (DOB)' : 'Step 1: Your Date of Birth'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _pickDateOfBirth(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.accentGold.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.cake_rounded, color: theme.accentGold, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedDob != null
                                        ? DateFormat('dd MMMM yyyy').format(_selectedDob!)
                                        : 'Select Date of Birth',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3E2723),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lang == 'kn' ? 'ಬದಲಾಯಿಸಿ 📅' : (lang == 'hi' ? 'बदलें 📅' : 'Change 📅'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedDob != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildMiniTag('ಮೂಲಾಂಕ: $mulank', 'मूल अंक: $mulank', 'Root: $mulank', theme),
                            const SizedBox(width: 8),
                            _buildMiniTag('ಭಾಗ್ಯಾಂಕ: $bhagyank', 'भाग्यांक: $bhagyank', 'Destiny: $bhagyank', theme),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildMiniTag('ಗ್ರಹಾಧಿಪತಿ: ${_getPlanetForNumber(mulank, lang)}', 'ग्रह स्वामी: ${_getPlanetForNumber(mulank, lang)}', 'Ruler: ${_getPlanetForNumber(mulank, lang)}', theme),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // STEP 2: Sacred Dice Roll (Vedic Prashna with 5-Min Lock)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFDF8), Color(0xFFFFF3E0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.accentGold.withOpacity(0.6), width: 1.3),
                    boxShadow: [
                      BoxShadow(
                        color: theme.accentGold.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.casino_rounded, color: theme.accentGold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            lang == 'kn'
                                ? 'ಹಂತ ೨: ${widget.rashi.name} ಕವಡೆ ಪ್ರಶ್ನ ಶಾಸ್ತ್ರ'
                                : (lang == 'hi' ? 'चरण २: ${widget.rashi.name} वैदिक पासा फल' : 'Step 2: ${widget.rashi.name} Vedic Dice Roll'),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Animated Dice Graphic
                      RotationTransition(
                        turns: _diceRotationAnim,
                        child: GestureDetector(
                          onTap: isCooldownActive ? null : _rollDiceAndCalculate,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _diceNumber > 0
                                    ? [theme.primaryColor, const Color(0xFF8B263E)]
                                    : [const Color(0xFFF7ECE1), const Color(0xFFE6D2BC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.accentGold,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.accentGold.withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isRolling
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                  : (_diceNumber > 0
                                      ? Text(
                                          _getDiceSymbol(_diceNumber),
                                          style: TextStyle(
                                            fontSize: 44,
                                            color: theme.accentGold,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.touch_app_rounded,
                                          size: 38,
                                          color: Color(0xFF8D6E63),
                                        )),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Roll Button with 5-Minute Cooldown Guard
                      ElevatedButton.icon(
                        onPressed: isCooldownActive ? null : _rollDiceAndCalculate,
                        icon: Icon(isCooldownActive ? Icons.lock_clock_outlined : Icons.casino_outlined, size: 18),
                        label: Text(
                          isCooldownActive
                              ? (lang == 'kn'
                                  ? 'ಕಾಯುವಿಕೆ: ${_formatCooldown(_cooldownSecondsRemaining)} ⏳'
                                  : (lang == 'hi'
                                      ? 'प्रतीक्षा करें: ${_formatCooldown(_cooldownSecondsRemaining)} ⏳'
                                      : 'Next Roll in ${_formatCooldown(_cooldownSecondsRemaining)} ⏳'))
                              : (_hasCalculated
                                  ? (lang == 'kn' ? 'ಮತ್ತೊಮ್ಮೆ ಲೆಕ್ಕ ಹಾಕಿ 🎲' : (lang == 'hi' ? 'पुनः गणना करें 🎲' : 'Recalculate Luck 🎲'))
                                  : (lang == 'kn' ? 'ಕವಡೆ ಉರುಳಿಸಿ ಲೈವ್ ಅದೃಷ್ಟ ಪಡೆಯಿರಿ 🎲' : (lang == 'hi' ? 'पासा फेंकें व लाइव भाग्य जानें 🎲' : 'Roll Dice & Extract Live Luck 🎲'))),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCooldownActive ? Colors.grey.shade400 : theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: isCooldownActive ? 0 : 3,
                        ),
                      ),

                      if (_isFetchingLiveApi) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 8),
                            Text(
                              lang == 'kn'
                                  ? 'ಲೈವ್ ಅಂತರ್ಜಾಲ ಗ್ರಹಬಲ ಪಡೆಯಲಾಗುತ್ತಿದೆ 🌐...'
                                  : (lang == 'hi'
                                      ? 'लाइव इंटरनेट ग्रह बल निकाला जा रहा है 🌐...'
                                      : 'Extracting live cosmic feeds on-device 🌐...'),
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // STEP 3: REVEAL PERSONALIZED LUCK OF THE DAY FOR RASHI
                if (_hasCalculated) ...[
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE0D5C7)),
                      boxShadow: [
                        BoxShadow(
                          color: theme.accentGold.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Luck Score Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang == 'kn'
                                      ? '${widget.rashi.name} ಇಂದಿನ ಒಟ್ಟು ಗ್ರಹಬಲ'
                                      : (lang == 'hi' ? '${widget.rashi.name} आज का संपूर्ण भाग्य' : '${widget.rashi.name} Today\'s Total Luck'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF795548),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getLuckTitle(luckScore, lang),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [theme.primaryColor, const Color(0xFF9C27B0)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '$luckScore%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: luckScore / 100.0,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFF0E5D8),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              luckScore > 85 ? const Color(0xFF2E7D32) : theme.accentGold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // DYNAMIC INTERNET ON-DEVICE RASHI FORECAST BOX
                        if (_dynamicLiveForecast.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFC5E1A5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.public_rounded, color: Color(0xFF2E7D32), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      lang == 'kn'
                                          ? 'ಲೈವ್ ಅಂತರ್ಜಾಲ ಭವಿಷ್ಯ (${widget.rashi.name}) 🌐'
                                          : (lang == 'hi'
                                              ? 'लाइव इंटरनेट भविष्यवाणी (${widget.rashi.name}) 🌐'
                                              : 'Live Internet Planetary Forecast (${widget.rashi.name}) 🌐'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _dynamicLiveForecast,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        const Divider(height: 1, color: Color(0xFFECE0D1)),
                        const SizedBox(height: 14),

                        // Personalized Pillars based on Rashi & Dice
                        _buildPillarRow(
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF2E7D32),
                          title: lang == 'kn' ? 'ಧನ ಲಾಭ & ಆರ್ಥಿಕ' : (lang == 'hi' ? 'धन लाभ व वित्तीय' : 'Financial & Wealth Luck'),
                          detail: _getRashiFinancialAdvice(widget.rashi.id, luckScore, lang),
                        ),
                        const SizedBox(height: 12),
                        _buildPillarRow(
                          icon: Icons.work_history_rounded,
                          color: const Color(0xFF1565C0),
                          title: lang == 'kn' ? 'ಕಾರ್ಯ ಸಿದ್ಧಿ & ವೃತ್ತಿ' : (lang == 'hi' ? 'कार्य सिद्धि व करियर' : 'Career & Task Success'),
                          detail: _getRashiCareerAdvice(widget.rashi.id, luckScore, lang),
                        ),
                        const SizedBox(height: 12),
                        _buildPillarRow(
                          icon: Icons.spa_rounded,
                          color: const Color(0xFF6A1B9A),
                          title: lang == 'kn' ? 'ಮನಶ್ಶಾಂತಿ & ಕುಟುಂಬ' : (lang == 'hi' ? 'मानसिक शांति व परिवार' : 'Peace & Harmony'),
                          detail: _getRashiPeaceAdvice(widget.rashi.id, luckScore, lang),
                        ),
                        const SizedBox(height: 12),
                        _buildPillarRow(
                          icon: Icons.access_time_filled_rounded,
                          color: const Color(0xFFE65100),
                          title: lang == 'kn' ? 'ಶುಭ ಮುಹೂರ್ತ ಸಮಯ' : (lang == 'hi' ? 'शुभ मुहूर्त समय' : 'Golden Muhurtha Time'),
                          detail: _getGoldenHours(now.weekday, lang),
                        ),
                        const SizedBox(height: 12),
                        _buildPillarRow(
                          icon: Icons.flare_rounded,
                          color: theme.accentGold,
                          title: lang == 'kn' ? 'ದೈನಂದಿನ ದೈವಿಕ ಪರಿಹಾರ' : (lang == 'hi' ? 'आज का दिव्य उपाय' : 'Sacred Remedy for ${widget.rashi.name}'),
                          detail: _getRashiRemedy(widget.rashi.id, mulank, lang),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String kn, String hi, String en, TempleTheme theme) {
    final text = widget.currentLang == 'kn' ? kn : (widget.currentLang == 'hi' ? hi : en);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4E342E),
        ),
      ),
    );
  }

  Widget _buildPillarRow({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDiceSymbol(int n) {
    switch (n) {
      case 1: return '⚀';
      case 2: return '⚁';
      case 3: return '⚂';
      case 4: return '⚃';
      case 5: return '⚄';
      case 6: default: return '⚅';
    }
  }

  String _getLuckTitle(int score, String lang) {
    if (score >= 90) {
      return lang == 'kn' ? 'ಮಹಾ ಭಾಗ್ಯೋದಯ ಯೋಗ 🌟' : (lang == 'hi' ? 'महा भाग्योदय योग 🌟' : 'Peak Auspicious Alignment 🌟');
    } else if (score >= 80) {
      return lang == 'kn' ? 'ಉತ್ತಮ ಧನ-ಧಾನ್ಯ ಸಿದ್ಧಿ ✨' : (lang == 'hi' ? 'उत्तम धन-धान्य सिद्धि ✨' : 'Highly Auspicious & Blessed ✨');
    } else {
      return lang == 'kn' ? 'ಮಿಶ್ರ ಫಲ & ದೈವ ರಕ್ಷಣೆ 🛡️' : (lang == 'hi' ? 'मिश्रित फल व प्रभु रक्षा 🛡️' : 'Balanced & Protected Day 🛡️');
    }
  }

  String _getRashiFinancialAdvice(String rashiId, int score, String lang) {
    if (lang == 'kn') {
      switch (rashiId) {
        case 'mesha': return 'ಕುಜ ಪ್ರಭಾವದಿಂದ ಹೊಸ ಉದ್ಯಮ ಹಾಗೂ ಹೂಡಿಕೆಯಲ್ಲಿ ಲಾಭ.';
        case 'vrishabha': return 'ಶುಕ್ರನ ಕೃಪೆಯಿಂದ ಆಭರಣ ಹಾಗೂ ಸ್ಥಿರಾಸ್ತಿ ವ್ಯವಹಾರಗಳಲ್ಲಿ ಸಫಲತೆ.';
        case 'mithuna': return 'ಬುಧನ ಪ್ರಭಾವದಿಂದ ವ್ಯಾಪಾರ ಹಾಗೂ ಷೇರು ಮಾರುಕಟ್ಟೆಯಲ್ಲಿ ಧನ ಲಾಭ.';
        case 'karka': return 'ಚಂದ್ರನ ಕೃಪೆಯಿಂದ ಕುಟುಂಬದ ಆಸ್ತಿ ವೃದ್ಧಿ ಹಾಗೂ ಉಳಿತಾಯ.';
        case 'simha': return 'ಸೂರ್ಯನ ಪ್ರಭಾವದಿಂದ ಅಧಿಕಾರ ಹಾಗೂ ಸರ್ಕಾರಿ ಯೋಜನೆಗಳಿಂದ ಧನಾಗಮನ.';
        case 'kanya': return 'ಬುದ್ಧಿವಂತಿಕೆಯ ಲೆಕ್ಕಾಚಾರದಿಂದ ಖರ್ಚು ನಿಯಂತ್ರಣ ಹಾಗೂ ಲಾಭ.';
        case 'tula': return 'ಪಾಲುದಾರಿಕೆ ವ್ಯವಹಾರಗಳಲ್ಲಿ ಉತ್ತಮ ಆದಾಯ ಹಾಗೂ ಹೊಸ ಅವಕಾಶ.';
        case 'vrishchika': return 'ಬಾಕಿ ವಸೂಲಾತಿ ತೃಪ್ತಿದಾಯಕ, ಅನಿರೀಕ್ಷಿತ ಧನಾಗಮನ ಯೋಗ.';
        case 'dhanu': return 'ಗುರು ಬಲದಿಂದ ಧಾರ್ಮಿಕ ಮತ್ತು ವ್ಯವಹಾರಿಕ ಹೂಡಿಕೆಗಳಲ್ಲಿ ಸಮೃದ್ಧಿ.';
        case 'makara': return 'ಶ್ರಮಕ್ಕೆ ತಕ್ಕ ಪ್ರತಿಫಲ, ದೀರ್ಘಾವಧಿ ಉಳಿತಾಯ ಯೋಜನೆಗಳು ಶುಭ.';
        case 'kumbha': return 'ನವೀನ ಯೋಜನೆಗಳಿಗೆ ಧನಸಹಾಯ ಲಭ್ಯ, ಆರ್ಥಿಕ ಸ್ಥಿರತೆ.';
        case 'meena': default: return 'ಗುರು ಕೃಪೆಯಿಂದ ಸಂಪತ್ತಿನ ವೃದ್ಧಿ ಹಾಗೂ ಪುಣ್ಯ ಕಾರ್ಯಗಳಿಗೆ ವೆಚ್ಚ.';
      }
    } else if (lang == 'hi') {
      switch (rashiId) {
        case 'mesha': return 'मंगल के प्रभाव से नए व्यापार व निवेश में शुभ लाभ।';
        case 'vrishabha': return 'शुक्र कृपा से आभूषण व संपत्ति से लाभ होगा।';
        case 'mithuna': return 'बुध के प्रभाव से व्यापार में धन लाभ के योग।';
        case 'karka': return 'चंद्र की कृपा से पारिवारिक संपत्ति व बचत में वृद्धि।';
        case 'simha': return 'सूर्य देव के प्रभाव से सरकारी व उच्च कार्यों से लाभ।';
        case 'kanya': return 'बुद्धि व विवेक से वित्तीय निर्णयों में उत्तम सफलता।';
        case 'tula': return 'साझेदारी के कार्यों में अच्छा लाभ व नए अवसर।';
        case 'vrishchika': return 'रुका हुआ धन वापस मिलने के शुभ योग।';
        case 'dhanu': return 'गुरु के आशीर्वाद से धन-धान्य में समृद्धि।';
        case 'makara': return 'कठिन परिश्रम का उचित प्रतिफल मिलेगा।';
        case 'kumbha': return 'नई योजनाओं के लिए आर्थिक सहयोग प्राप्त होगा।';
        case 'meena': default: return 'शुभ कार्यों व दान-पुण्य से आत्मिक व भौतिक लाभ।';
      }
    }
    switch (rashiId) {
      case 'mesha': return 'Mars brings dynamic breakthroughs in enterprise and bold financial initiatives.';
      case 'vrishabha': return 'Venus bestows luxurious comfort and profitable property/material acquisitions.';
      case 'mithuna': return 'Mercury sharpens commercial intellect, ensuring lucrative trades and negotiations.';
      case 'karka': return 'Moon stabilizes domestic reserves and brings fruitful returns on past savings.';
      case 'simha': return 'Sun elevates executive authority, bringing governmental or corporate financial support.';
      case 'kanya': return 'Analytical mastery prevents waste and yields substantial long-term dividends.';
      case 'tula': return 'Venus balances partnerships, inviting prosperous joint ventures and contracts.';
      case 'vrishchika': return 'Mars and Ketu resolve pending arrears and bring unexpected monetary relief.';
      case 'dhanu': return 'Jupiter magnifies wealth through wisdom, educational, and noble projects.';
      case 'makara': return 'Saturn rewards disciplined patience with steady, compounding material progress.';
      case 'kumbha': return 'Innovative concepts attract investor interest and ensure financial equilibrium.';
      case 'meena': default: return 'Jupiter showers divine benevolence, multiplying both spiritual and material provisions.';
    }
  }

  String _getRashiCareerAdvice(String rashiId, int score, String lang) {
    if (lang == 'kn') {
      return 'ಕಾರ್ಯಕ್ಷೇತ್ರದಲ್ಲಿ ಗೌರವ ವೃದ್ಧಿ, ಸಹೋದ್ಯೋಗಿಗಳಿಂದ ಸಂಪೂರ್ಣ ಸಹಕಾರ.';
    } else if (lang == 'hi') {
      return 'कार्यक्षेत्र में मान-सम्मान बढ़ेगा व उच्चाधिकारियों की प्रशंसा मिलेगी।';
    }
    return 'Professional tasks proceed smoothly with clear appreciation from mentors.';
  }

  String _getRashiPeaceAdvice(String rashiId, int score, String lang) {
    if (lang == 'kn') {
      return 'ಮನೆಯಲ್ಲಿ ಸೌಹಾರ್ದಯುತ ವಾತಾವರಣ, ಗುರು-ಹಿರಿಯರ ಆಶೀರ್ವಾದದಿಂದ ನೆಮ್ಮದಿ.';
    } else if (lang == 'hi') {
      return 'पारिवारिक वातावरण सुखद रहेगा और मानसिक शांति का अनुभव होगा।';
    }
    return 'Harmonious domestic life; quiet meditation brings profound peace.';
  }

  String _getGoldenHours(int weekday, String lang) {
    switch (weekday) {
      case DateTime.monday: return '09:15 AM – 10:45 AM & 04:30 PM – 06:00 PM';
      case DateTime.tuesday: return '08:30 AM – 10:00 AM & 02:00 PM – 03:30 PM';
      case DateTime.wednesday: return '07:30 AM – 09:00 AM & 03:00 PM – 04:30 PM';
      case DateTime.thursday: return '10:00 AM – 11:30 AM & 05:00 PM – 06:30 PM';
      case DateTime.friday: return '08:00 AM – 09:30 AM & 04:00 PM – 05:30 PM';
      case DateTime.saturday: return '07:00 AM – 08:30 AM & 03:30 PM – 05:00 PM';
      case DateTime.sunday: default: return '09:30 AM – 11:00 AM & 03:00 PM – 04:30 PM';
    }
  }

  String _getRashiRemedy(String rashiId, int mulank, String lang) {
    if (lang == 'kn') {
      switch (rashiId) {
        case 'mesha':
        case 'vrishchika': return 'ಹನುಮಾನ್ ಚಾಲೀಸಾ ಪಠಿಸಿ ಅಥವಾ ಸುಬ್ರಹ್ಮಣ್ಯ ಸ್ವಾಮಿಗೆ ನಮಸ್ಕರಿಸಿ.';
        case 'vrishabha':
        case 'tula': return 'ಮಹಾಲಕ್ಷ್ಮಿ ಅಷ್ಟಕಂ ಪಠಿಸಿ, ತುಪ್ಪದ ದೀಪ ಹಚ್ಚಿ.';
        case 'mithuna':
        case 'kanya': return 'ಶ್ರೀ ವಿಷ್ಣು ಸಹಸ್ರನಾಮ ಶ್ರವಣ ಮಾಡಿ ಅಥವಾ ಹಸಿರು ಧಾನ್ಯ ದಾನ ಮಾಡಿ.';
        case 'karka': return 'ಶಿವಲಿಂಗಕ್ಕೆ ಜಲಾಭಿಷೇಕ ಮಾಡಿ ಓಂ ನಮಃ ಶಿವಾಯ ಜಪಿಸಿ.';
        case 'simha': return 'ಸೂರ್ಯದೇವರಿಗೆ ಅರ್ಘ್ಯ ಅರ್ಪಿಸಿ ಆದಿತ್ಯ ಹೃದಯ ಸ್ತೋತ್ರ ಪಠಿಸಿ.';
        case 'dhanu':
        case 'meena': return 'ಶ್ರೀ ರಾಘವೇಂದ್ರ ಸ್ವಾಮಿ ಅಥವಾ ಗುರುಗಳ ಧ್ಯಾನ ಮಾಡಿ.';
        case 'makara':
        case 'kumbha': default: return 'ಶನೈಶ್ಚರ ಸ್ತೋತ್ರ ಪಠಿಸಿ ಅಥವಾ ಕಾಗೆಗಳಿಗೆ ಅನ್ನ ನೀಡಿ.';
      }
    } else if (lang == 'hi') {
      switch (rashiId) {
        case 'mesha':
        case 'vrishchika': return 'हनुमान चालीसा का पाठ करें व लाल पुष्प अर्पित करें।';
        case 'vrishabha':
        case 'tula': return 'महालक्ष्मी अष्टकम का पाठ करें व घी का दीपक जलाएं।';
        case 'mithuna':
        case 'kanya': return 'विष्णु सहस्रनाम का श्रवण करें या पक्षियों को दाना दें।';
        case 'karka': return 'शिवलिंग पर जलाभिषेक करें व ॐ नमः शिवाय का जप करें।';
        case 'simha': return 'सूर्य देव को जल का अर्घ्य दें व आदित्य हृदयम पढ़ें।';
        case 'dhanu':
        case 'meena': return 'श्री गुरुदेव या भगवान दत्तात्रेय का ध्यान करें।';
        case 'makara':
        case 'kumbha': default: return 'शनि मंत्र का जप करें व जरूरतमंदों की सहायता करें।';
      }
    }
    switch (rashiId) {
      case 'mesha':
      case 'vrishchika': return 'Chant Hanuman Chalisa and offer prayers to Lord Subramanya.';
      case 'vrishabha':
      case 'tula': return 'Recite Mahalakshmi Ashtakam and light a pure ghee lamp.';
      case 'mithuna':
      case 'kanya': return 'Listen to Vishnu Sahasranamam and offer fresh Tulasi leaves.';
      case 'karka': return 'Perform milk/water offering to Lord Shiva with Om Namah Shivaya.';
      case 'simha': return 'Offer morning water (Arghya) to the Sun and recite Aditya Hridayam.';
      case 'dhanu':
      case 'meena': return 'Meditate on Sri Guru Raghavendra Swamy with Guru Stotram.';
      case 'makara':
      case 'kumbha': default: return 'Chant Shanaishchara Stotram and practice acts of humble charity.';
    }
  }
}
