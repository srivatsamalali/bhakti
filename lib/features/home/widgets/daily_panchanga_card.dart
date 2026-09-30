import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/temple_theme.dart';
import '../../../../services/panchanga/panchanga_service.dart';
import '../../../../services/preferences/preferences_service.dart';
import '../../../widgets/moon_phase_dial.dart';
import '../../wallpaper/sacred_wallpaper_generator_dialog.dart';

class DailyPanchangaCard extends StatefulWidget {
  const DailyPanchangaCard({super.key});

  @override
  State<DailyPanchangaCard> createState() => _DailyPanchangaCardState();
}

class _DailyPanchangaCardState extends State<DailyPanchangaCard> {
  bool _isExpanded = false;
  int _activeSegment = 0; // 0: Today, 1: Calendar, 2: Rashi Chart
  int _selectedRashiIndex = 0;
  DateTime _calendarMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = context.read<PreferencesService>().getSelectedLanguage();
      context.read<PanchangaService>().getPanchangaForLanguage(lang);
    });
  }

  String _getText(String key, String lang) {
    if (lang == 'kn') {
      switch (key) {
        case 'tab_today': return 'ಇಂದು';
        case 'tab_calendar': return 'ಕ್ಯಾಲೆಂಡರ್';
        case 'tab_rashi': return 'ರಾಶಿ ಫಲ';
        case 'auspicious': return 'ಶುಭ ಕಾಲ';
        case 'inauspicious': return 'ರಾಹು / ಯಮಗಂಡ';
        case 'brahma': return 'ಬ್ರಹ್ಮ ಮುಹೂರ್ತ';
        case 'abhijit': return 'ಅಭಿಜಿತ್ ಮುಹೂರ್ತ';
        case 'rahu': return 'ರಾಹು ಕಾಲ';
        case 'yama': return 'ಯಮಗಂಡ';
        case 'gulika': return 'ಗುಳಿಕ ಕಾಲ';
        case 'festivals': return 'ಮುಂಬರುವ ಪವಿತ್ರ ವ್ರತಗಳು & ಹಬ್ಬಗಳು';
        case 'badge': return 'ಪಂಚಾಂಗ';
        case 'today': return 'ಇಂದು';
        case 'rashi_title': return 'ದೈನಂದಿನ ರಾಶಿ ಭವಿಷ್ಯ & ಕುಂಡಲಿ ಫಲ';
        case 'lucky_color': return 'ಶುಭ ಬಣ್ಣ';
        case 'lucky_num': return 'ಶುಭ ಸಂಖ್ಯೆ';
        case 'ruler': return 'ಅಧಿಪತಿ';
        case 'mantra': return 'ಮಂತ್ರ ಜಪ';
        case 'deity': return 'ಆರಾಧ್ಯ ದೇವತೆ';
        case 'tithi': return 'ತಿಥಿ';
        case 'paksha': return 'ಪಕ್ಷ';
        case 'nakshatra': return 'ನಕ್ಷತ್ರ';
        case 'live_sync': return 'ಲೈವ್ ಪಂಚಾಂಗ ಸಿಂಕ್';
      }
    } else if (lang == 'hi') {
      switch (key) {
        case 'tab_today': return 'आज';
        case 'tab_calendar': return 'कैलेंडर';
        case 'tab_rashi': return 'राशिफल';
        case 'auspicious': return 'शुभ मुहूर्त';
        case 'inauspicious': return 'राहुकाल / यमगंड';
        case 'brahma': return 'ब्रह्म मुहूर्त';
        case 'abhijit': return 'अभिजित मुहूर्त';
        case 'rahu': return 'राहुकाल';
        case 'yama': return 'यमगंड';
        case 'gulika': return 'गुलिक काल';
        case 'festivals': return 'आगामी पावन व्रत एवं त्यौहार';
        case 'badge': return 'पंचांग';
        case 'today': return 'आज';
        case 'rashi_title': return 'दैनिक राशिफल एवं कुण्डली मार्गदर्शन';
        case 'lucky_color': return 'शुभ रंग';
        case 'lucky_num': return 'शुभ अंक';
        case 'ruler': return 'स्वामी ग्रह';
        case 'mantra': return 'दैनिक मंत्र';
        case 'deity': return 'आराध्य देवता';
        case 'tithi': return 'तिथि';
        case 'paksha': return 'पक्ष';
        case 'nakshatra': return 'नक्षत्र';
        case 'live_sync': return 'लाइव पंचांग सिंक';
      }
    } else if (lang == 'ta') {
      switch (key) {
        case 'tab_today': return 'இன்று';
        case 'tab_calendar': return 'நாட்காட்டி';
        case 'tab_rashi': return 'ராசி பலன்';
        case 'auspicious': return 'சுப காலம்';
        case 'inauspicious': return 'ராகு / எமகண்டம்';
        case 'brahma': return 'பிரம்ம முகூர்த்தம்';
        case 'abhijit': return 'அபிஜித் முகூர்த்தம்';
        case 'rahu': return 'ராகு காலம்';
        case 'yama': return 'எமகண்டம்';
        case 'gulika': return 'குளிகை காலம்';
        case 'festivals': return 'வரவிருக்கும் புனித விரதங்கள் & பண்டிகைகள்';
        case 'badge': return 'பஞ்சாங்கம்';
        case 'today': return 'இன்று';
        case 'rashi_title': return 'தினசரி ராசி பலன்கள்';
        case 'lucky_color': return 'அதிர்ஷ்ட நிறம்';
        case 'lucky_num': return 'அதிர்ஷ்ட எண்';
        case 'ruler': return 'அதிபதி கிரகம்';
        case 'mantra': return 'மந்திரம்';
        case 'deity': return 'வழிபாட்டு தெய்வம்';
        case 'tithi': return 'திதி';
        case 'paksha': return 'பக்ஷம்';
        case 'nakshatra': return 'நட்சத்திரம்';
        case 'live_sync': return 'நேரலை பஞ்சாங்கம்';
      }
    } else if (lang == 'ml') {
      switch (key) {
        case 'tab_today': return 'ഇന്ന്';
        case 'tab_calendar': return 'കലണ്ടർ';
        case 'tab_rashi': return 'രാശിഫലം';
        case 'auspicious': return 'ശുഭ സമയം';
        case 'inauspicious': return 'രാഹുകാലം / യമഗണ്ഡം';
        case 'brahma': return 'ബ്രഹ്മമുഹൂർത്തം';
        case 'abhijit': return 'അഭിജിത് മുഹൂർത്തം';
        case 'rahu': return 'രാഹുകാലം';
        case 'yama': return 'യമഗണ്ഡം';
        case 'gulika': return 'ഗുളിക കാലം';
        case 'festivals': return 'വരാനിരിക്കുന്ന പവിത്ര വ്രതങ്ങളും ഉത്സവങ്ങളും';
        case 'badge': return 'പഞ്ചാംഗം';
        case 'today': return 'ഇന്ന്';
        case 'rashi_title': return 'ദിവസേനയുള്ള രാശിഫലം';
        case 'lucky_color': return 'ഭാഗ്യ നിറം';
        case 'lucky_num': return 'ഭാഗ്യ സംഖ്യ';
        case 'ruler': return 'അധിപൻ';
        case 'mantra': return 'മന്ത്രം';
        case 'deity': return 'ആരാധ്യ ദേവൻ';
        case 'tithi': return 'തിഥി';
        case 'paksha': return 'പക്ഷം';
        case 'nakshatra': return 'നക്ഷത്രം';
        case 'live_sync': return 'തത്സമയ പഞ്ചാംഗം';
      }
    }

    switch (key) {
      case 'tab_today': return 'Today';
      case 'tab_calendar': return 'Calendar';
      case 'tab_rashi': return 'Rashi Chart';
      case 'auspicious': return 'Auspicious (Shubha)';
      case 'inauspicious': return 'Rahu / Yama';
      case 'brahma': return 'Brahma';
      case 'abhijit': return 'Abhijit';
      case 'rahu': return 'Rahu';
      case 'yama': return 'Yama';
      case 'gulika': return 'Gulika';
      case 'festivals': return 'UPCOMING SACRED VRATAS & FESTIVALS';
      case 'badge': return 'Panchanga';
      case 'today': return 'Today';
      case 'rashi_title': return 'Daily Vedic Rashi Forecast & Guidance';
      case 'lucky_color': return 'Lucky Color';
      case 'lucky_num': return 'Lucky No.';
      case 'ruler': return 'Ruling Planet';
      case 'mantra': return 'Sacred Mantra';
      case 'deity': return 'Presiding Deity';
      case 'tithi': return 'Tithi';
      case 'paksha': return 'Paksha';
      case 'nakshatra': return 'Nakshatra';
      case 'live_sync': return 'Live Vedic Sync';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final panchangaService = context.watch<PanchangaService>();
    final currentLang = prefs.getSelectedLanguage();
    final templeTheme = TempleTheme.fromId(prefs.getTempleThemeId());
    final data = panchangaService.getTodayPanchanga(currentLang);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: templeTheme.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: templeTheme.accentGold.withOpacity(0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: templeTheme.primaryColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Header Row (Tappable to expand)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Vedic Sun / Spiritual Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: templeTheme.heroGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: templeTheme.primaryColor.withOpacity(0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.wb_twilight_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Today's Panchanga Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.dayOfWeek,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: templeTheme.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.tithi} • ${data.paksha.replaceAll(RegExp(r'\(.*?\)'), '').trim()}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B584C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Expand / Collapse Chevron
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF4EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: templeTheme.borderColor),
                    ),
                    child: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: templeTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Detailed Content (Today / Calendar / Rashi Chart)
          if (_isExpanded) ...[
            Divider(color: templeTheme.borderColor, height: 1, indent: 16, endIndent: 16),
            
            // Segmented Navigation Bar with Single Sliding Capsule
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EDE4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final segmentWidth = constraints.maxWidth / 3;
                    return Stack(
                      children: [
                        // Single Smooth Sliding Active Indicator (Zero lag & Zero residual ghost shade)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          left: _activeSegment * segmentWidth,
                          top: 0,
                          bottom: 0,
                          width: segmentWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Interactive Tab Items
                        Row(
                          children: [
                            _buildSegmentItem(0, '☀️ ${_getText('tab_today', currentLang)}', templeTheme),
                            _buildSegmentItem(1, '📅 ${_getText('tab_calendar', currentLang)}', templeTheme),
                            _buildSegmentItem(2, '♈ ${_getText('tab_rashi', currentLang)}', templeTheme),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _activeSegment == 0
                    ? _buildTodayTab(context, data, currentLang, templeTheme)
                    : (_activeSegment == 1
                        ? _buildCalendarTab(context, panchangaService, currentLang, templeTheme)
                        : _buildRashiChartTab(context, panchangaService, currentLang, templeTheme)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentItem(int index, String label, TempleTheme templeTheme) {
    final isSelected = _activeSegment == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_activeSegment != index) {
            HapticFeedback.selectionClick();
            setState(() {
              _activeSegment = index;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.transparent,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? templeTheme.primaryColor : const Color(0xFF7D6B5E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLunarDetailTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 13),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8D4F37),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4E342E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 1: TODAY'S PANCHANGA DETAILS ---
  Widget _buildTodayTab(BuildContext context, PanchangaData data, String lang, TempleTheme templeTheme) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deity of the Day & Special Occasion banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFF8F00), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.deityOfTheDay,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                ],
              ),
              if (data.specialOccasion.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  data.specialOccasion,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: templeTheme.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Celestial Lunar & Solar Tithi Orb Card (Subtle Saffron-Amber Theme)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF6EB), Color(0xFFFDECDA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD5A5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8F00).withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Moon Phase Dial + Tithi & Paksha Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MoonPhaseDial(
                    tithiName: data.tithi,
                    paksha: data.paksha,
                    size: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.tithi,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: templeTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0B2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFCC80), width: 0.8),
                          ),
                          child: Text(
                            data.paksha,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD84315),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFFFE0B2)),
              const SizedBox(height: 10),

              // 2x2 Vedic Attributes Grid (Full text visible, no truncation!)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildLunarDetailTile(
                      icon: Icons.star_border_purple500_rounded,
                      iconColor: const Color(0xFFE65100),
                      label: _getText('nakshatra', lang),
                      value: data.nakshatra,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLunarDetailTile(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF8E24AA),
                      label: 'Yoga',
                      value: data.yoga,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildLunarDetailTile(
                      icon: Icons.wb_twilight_rounded,
                      iconColor: const Color(0xFFF57C00),
                      label: 'Karana',
                      value: data.karana,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLunarDetailTile(
                      icon: Icons.wb_sunny_outlined,
                      iconColor: const Color(0xFFE65100),
                      label: _getText('brahma', lang),
                      value: data.brahmaMuhurta,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Auspicious & Inauspicious Times Grid
        Row(
          children: [
            // Auspicious Box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getText('auspicious', lang),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_getText('brahma', lang)}: ${data.brahmaMuhurta}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getText('abhijit', lang)}: ${data.abhijitMuhurta}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Inauspicious Box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCCBC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled, color: Color(0xFFC62828), size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getText('inauspicious', lang),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC62828),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_getText('rahu', lang)}: ${data.rahuKalam}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFFB71C1C), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getText('yama', lang)}: ${data.yamaGandam}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFFB71C1C), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Upcoming Festivals List
        Text(
          _getText('festivals', lang),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8B776A),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),

        ...data.upcomingFestivals.take(3).map((fest) {
          final isToday = fest.daysRemaining == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFFFF8E1) : const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday ? const Color(0xFFFFC107) : const Color(0xFFECDCC9),
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFFE65100) : templeTheme.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isToday ? _getText('today', lang) : '${fest.daysRemaining}d',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fest.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isToday ? const Color(0xFFBF360C) : const Color(0xFF3E2723),
                        ),
                      ),
                      Text(
                        '${fest.deity} • ${fest.date}',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF795548)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        // 1-Tap Panchanga Story & Wallpaper Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(Icons.wallpaper_rounded, size: 16, color: templeTheme.primaryColor),
            label: const Text('Create Panchanga Story & Wallpaper 🖼️', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: templeTheme.primaryColor,
              side: BorderSide(color: templeTheme.borderColor, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              SacredWallpaperGeneratorDialog.show(
                context,
                shlokaTitle: 'Daily Panchanga • ${data.dayOfWeek}',
                deity: 'Vedic Panchanga Blessings',
                panchangaSummary: 'Tithi: ${data.tithi}\nPaksha: ${data.paksha}\nNakshatra: ${data.nakshatra}\nYoga: ${data.yoga} • Karana: ${data.karana}\n\nBrahma Muhurta: ${data.brahmaMuhurta}',
                shlokaMeaning: 'Auspicious Abhijit: ${data.abhijitMuhurta} • Rahu Kalam: ${data.rahuKalam}',
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: VEDIC MONTH CALENDAR ---
  Widget _buildCalendarTab(BuildContext context, PanchangaService service, String lang, TempleTheme templeTheme) {
    final days = service.getMonthCalendarDays(_calendarMonth, lang);
    final monthTitle = DateFormat('MMMM yyyy').format(_calendarMonth);

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Navigation Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: templeTheme.primaryColor),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                });
              },
            ),
            Text(
              monthTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: templeTheme.primaryColor,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: templeTheme.primaryColor),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Grid of Month Days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.82,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final isSpecial = day.isGrahana || day.isHunnime || day.isAmavasya || day.isAuspicious;
            
            Color cellBg;
            Color cellBorder;
            if (day.isToday) {
              cellBg = templeTheme.primaryColor;
              cellBorder = templeTheme.accentGold;
            } else if (day.isGrahana) {
              cellBg = const Color(0xFFFFEBEE);
              cellBorder = const Color(0xFFE53935);
            } else if (day.isHunnime) {
              cellBg = const Color(0xFFFFF9C4);
              cellBorder = const Color(0xFFFFB300);
            } else if (day.isAmavasya) {
              cellBg = const Color(0xFFECEFF1);
              cellBorder = const Color(0xFF78909C);
            } else if (day.isAuspicious) {
              cellBg = const Color(0xFFFFF8E1);
              cellBorder = const Color(0xFFFFCA28);
            } else {
              cellBg = const Color(0xFFFAF7F2);
              cellBorder = const Color(0xFFE8DECF);
            }

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.selectionClick();
                _showDayPanchangaPopup(context, day, service, lang, templeTheme);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cellBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cellBorder,
                    width: (day.isToday || day.isGrahana || day.isHunnime || day.isAmavasya) ? 1.5 : 0.8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: day.isToday
                                ? Colors.white
                                : (day.isGrahana ? const Color(0xFFC62828) : const Color(0xFF3E2723)),
                          ),
                        ),
                        if (day.isGrahana) ...[
                          const SizedBox(width: 2),
                          const Text('🌘', style: TextStyle(fontSize: 8)),
                        ] else if (day.isHunnime) ...[
                          const SizedBox(width: 2),
                          const Text('🌕', style: TextStyle(fontSize: 8)),
                        ] else if (day.isAmavasya) ...[
                          const SizedBox(width: 2),
                          const Text('🌑', style: TextStyle(fontSize: 8)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      day.tithi,
                      style: TextStyle(
                        fontSize: 7.2,
                        fontWeight: FontWeight.w600,
                        color: day.isToday
                            ? Colors.white70
                            : (day.isGrahana ? const Color(0xFFB71C1C) : const Color(0xFF795548)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (day.festivalName != null || isSpecial) ...[
                      const SizedBox(height: 1),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: day.isToday
                              ? Colors.amberAccent
                              : (day.isGrahana
                                  ? const Color(0xFFD32F2F)
                                  : (day.isHunnime
                                      ? const Color(0xFFFFA000)
                                      : (day.isAmavasya ? const Color(0xFF455A64) : const Color(0xFFE65100)))),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        // Festival & Sacred Days Legend in this month
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Color(0xFFE65100), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    (lang == 'kn') ? 'ಈ ತಿಂಗಳ ಪವಿತ್ರ ವ್ರತಗಳು & ವಿಶೇಷ ದಿನಗಳು' : 'Vratas & Special Days This Month',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...days.where((d) => d.festivalName != null || d.isGrahana || d.isHunnime || d.isAmavasya).map((d) {
                String eventTitle = d.festivalName ?? '';
                String eventIcon = '🚩';
                Color tagColor = templeTheme.primaryColor;

                if (d.isGrahana) {
                  eventIcon = '🌘';
                  tagColor = const Color(0xFFC62828);
                  eventTitle = d.grahanaName ?? ((lang == 'kn') ? 'ಗ್ರಹಣ ಕಾಲ' : 'Eclipse');
                  if (d.festivalName != null && d.festivalName != d.grahanaName) {
                    eventTitle += ' • ${d.festivalName}';
                  }
                } else if (d.isHunnime) {
                  eventIcon = '🌕';
                  tagColor = const Color(0xFFE65100);
                  final hunnimeTitle = (lang == 'kn') ? 'ಹುಣ್ಣಿಮೆ (ಸತ್ಯನಾರಾಯಣ ಪೂಜೆ)' : 'Purnima / Full Moon';
                  eventTitle = d.festivalName != null ? '${d.festivalName!} • $hunnimeTitle' : hunnimeTitle;
                } else if (d.isAmavasya) {
                  eventIcon = '🌑';
                  tagColor = const Color(0xFF455A64);
                  final amavasyaTitle = (lang == 'kn') ? 'ಅಮಾವಾಸ್ಯೆ (ಪಿತೃ ತರ್ಪಣ/ಶಾಂತಿ)' : 'Amavasya / New Moon';
                  eventTitle = d.festivalName != null ? '${d.festivalName!} • $amavasyaTitle' : amavasyaTitle;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$eventIcon ${d.day}',
                          style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$eventTitle (${d.tithi})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3E2723)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showDayPanchangaPopup(BuildContext context, VedicDayInfo day, PanchangaService service, String lang, TempleTheme templeTheme) {
    final dayData = service.getPanchangaForDate(day.date, lang);
    final now = DateTime.now();
    final isTomorrow = day.date.year == now.year && day.date.month == now.month && day.date.day == now.day + 1;
    final dateFormatted = DateFormat('EEEE, d MMMM yyyy').format(day.date);

    String dateBadge = '';
    if (day.isToday) {
      dateBadge = (lang == 'kn') ? 'ಇಂದು' : (lang == 'hi' ? 'आज' : 'Today');
    } else if (isTomorrow) {
      dateBadge = (lang == 'kn') ? 'ನಾಳೆ' : (lang == 'hi' ? 'कल' : 'Tomorrow');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: templeTheme.borderColor, width: 1.8),
        ),
        contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sacred Header with Theme Sun
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: templeTheme.heroGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: templeTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              dayData.dayOfWeek,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: templeTheme.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (dateBadge.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: templeTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dateBadge,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormatted,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A685D), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: templeTheme.borderColor, height: 1),
            const SizedBox(height: 12),

            // Grahana (Eclipse) Special Banner if applicable
            if (day.isGrahana) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF5350), width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌘', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.grahanaName ?? ((lang == 'kn') ? 'ಗ್ರಹಣ ಕಾಲ' : 'Eclipse Period'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC62828),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (lang == 'kn')
                                ? 'ಗ್ರಹಣ ಸಮಯದಲ್ಲಿ ಜಪ-ಧ್ಯಾನ ಮತ್ತು ಈಶ್ವರ ಸ್ಮರಣೆ ಶ್ರೇಷ್ಠ. ಆಹಾರ ಸೇವನೆ ವರ್ಜಿಸಿ.'
                                : 'Chanting and meditation during eclipse brings highest spiritual merit.',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF5D4037)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Hunnime (Full Moon) Special Banner
            if (day.isHunnime) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌕', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (lang == 'kn') ? 'ಹುಣ್ಣಿಮೆ (ಪೌರ್ಣಮಿ)' : 'Purnima (Full Moon)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (lang == 'kn')
                                ? 'ಶ್ರೀ ಸತ್ಯನಾರಾಯಣ ಪೂಜೆ, ಲಕ್ಷ್ಮೀ ಆರಾಧನೆ ಹಾಗೂ ದೇವಸ್ಥಾನ ದರ್ಶನಕ್ಕೆ ಅತ್ಯಂತ ಶುಭದಾಯಕ.'
                                : 'Auspicious day for Sri Satyanarayana Vrata, Lakshmi Puja, and divine blessings.',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF5D4037)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Amavasya (New Moon) Special Banner
            if (day.isAmavasya) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFF1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF90A4AE), width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌑', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (lang == 'kn') ? 'ಅಮಾವಾಸ್ಯೆ' : 'Amavasya (New Moon)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (lang == 'kn')
                                ? 'ಪಿತೃ ತರ್ಪಣ, ಶಾಂತಿ ಪೂಜೆ ಮತ್ತು ನವಗ್ರಹ ಪ್ರಾರ್ಥನೆಗೆ ವಿಶೇಷ ಪ್ರಶಸ್ತ ದಿನ.'
                                : 'Dedicated day for Pitru Tarpanam, charity, and ancestral prayers.',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF5D4037)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tithi & Nakshatra Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF4EB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4D5C2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.tithi} (${day.paksha})',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: templeTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${dayData.nakshatra} • ${dayData.yoga}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF5D4037), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Festival Banner if any
            if (day.festivalName != null || dayData.specialOccasion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFE65100), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        day.festivalName ?? dayData.specialOccasion,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBF360C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Auspicious & Inauspicious Times
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getText('auspicious', lang), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        const SizedBox(height: 2),
                        Text('${_getText('brahma', lang)}:\n${dayData.brahmaMuhurta}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF1B5E20), height: 1.2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE9E7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getText('inauspicious', lang), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
                        const SizedBox(height: 2),
                        Text('${_getText('rahu', lang)}:\n${dayData.rahuKalam}', style: const TextStyle(fontSize: 9.5, color: Color(0xFFB71C1C), height: 1.2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                backgroundColor: templeTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: 12 RASHI CHART & KUNDALI GUIDANCE ---
  Widget _buildRashiChartTab(BuildContext context, PanchangaService service, String lang, TempleTheme templeTheme) {
    final now = DateTime.now();
    final rashis = service.getAllRashiDetails(lang, date: now);
    if (_selectedRashiIndex >= rashis.length) {
      _selectedRashiIndex = 0;
    }
    final selectedRashi = rashis[_selectedRashiIndex];

    final weekdayName = DateFormat('EEEE').format(now);
    final dayBhavishyaHeader = (lang == 'kn')
        ? 'ಇಂದಿನ ಗ್ರಹಬಲ ಭವಿಷ್ಯ ($weekdayName)'
        : (lang == 'hi' ? 'आज का दैनिक राशिफल ($weekdayName)' : "Today's Daily Rashi Bhavishya ($weekdayName)");

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily Bhavishya Subtitle Banner
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: templeTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: templeTheme.accentGold.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: templeTheme.accentGold, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  dayBhavishyaHeader,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: templeTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Rashi Selector Carousel
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rashis.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final rashi = rashis[index];
              final isSelected = index == _selectedRashiIndex;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedRashiIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? templeTheme.primaryColor : const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? templeTheme.accentGold : const Color(0xFFE4D7C8),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: templeTheme.primaryColor.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        rashi.symbol,
                        style: TextStyle(
                          fontSize: 18,
                          color: isSelected ? templeTheme.accentGold : const Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rashi.name.split(' ').first,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF3E2723),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Selected Rashi Detailed Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFDF9), Color(0xFFFFF7ED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: templeTheme.borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: templeTheme.accentGold.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Symbol, Name & Element
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: templeTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        selectedRashi.symbol,
                        style: TextStyle(fontSize: 22, color: templeTheme.accentGold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedRashi.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: templeTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '${_getText('ruler', lang)}: ${selectedRashi.rulingPlanet} • ${selectedRashi.element}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF795548), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Daily Prediction / Bhavishya
              Text(
                selectedRashi.prediction,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3E2723),
                ),
              ),

              const SizedBox(height: 12),

              // Lucky Color & Number Badges
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EDE4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getText('lucky_color', lang),
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF8D6E63), fontWeight: FontWeight.w600),
                          ),
                          Text(
                            selectedRashi.luckyColor,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EDE4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getText('lucky_num', lang),
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF8D6E63), fontWeight: FontWeight.w600),
                          ),
                          Text(
                            selectedRashi.luckyNumber,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Sacred Mantra Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFFE65100), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${_getText('mantra', lang)} (${selectedRashi.deity})',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBF360C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedRashi.mantra,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E342E),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
