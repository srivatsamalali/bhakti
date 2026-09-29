import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/panchanga/panchanga_service.dart';
import '../../../../services/preferences/preferences_service.dart';
import '../../../widgets/moon_phase_dial.dart';

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
    final data = panchangaService.getTodayPanchanga(currentLang);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                  // Saffron Vedic Sun Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8F00), Color(0xFFFF6F00)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6F00).withOpacity(0.25),
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                data.dayOfWeek,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.maroonPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getText('badge', currentLang),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.tithi} • ${data.nakshatra}',
                          style: const TextStyle(
                            fontSize: 13,
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
                      border: Border.all(color: const Color(0xFFECD7B8)),
                    ),
                    child: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.maroonPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Detailed Content (Today / Calendar / Rashi Chart)
          if (_isExpanded) ...[
            const Divider(color: Color(0xFFEADBCE), height: 1, indent: 16, endIndent: 16),
            
            // Segmented Navigation Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EDE4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton(0, '☀️ ${_getText('tab_today', currentLang)}'),
                    _buildSegmentButton(1, '📅 ${_getText('tab_calendar', currentLang)}'),
                    _buildSegmentButton(2, '♈ ${_getText('tab_rashi', currentLang)}'),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _activeSegment == 0
                    ? _buildTodayTab(context, data, currentLang)
                    : (_activeSegment == 1
                        ? _buildCalendarTab(context, panchangaService, currentLang)
                        : _buildRashiChartTab(context, panchangaService, currentLang)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final isSelected = _activeSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_activeSegment != index) {
            HapticFeedback.selectionClick();
            setState(() {
              _activeSegment = index;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.maroonPrimary : const Color(0xFF7D6B5E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: TODAY'S PANCHANGA DETAILS ---
  Widget _buildTodayTab(BuildContext context, PanchangaData data, String lang) {
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.maroonPrimary,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          child: Row(
            children: [
              MoonPhaseDial(
                tithiName: data.tithi,
                paksha: data.paksha,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${data.paksha} • ${data.tithi}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.maroonPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_getText('nakshatra', lang)}: ${data.nakshatra} • ${data.yoga}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF5D4037),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.wb_twilight_rounded, color: Color(0xFFE65100), size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Karana: ${data.karana} • ${_getText('brahma', lang)}: ${data.brahmaMuhurta}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF8D4F37),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getText('abhijit', lang)}: ${data.abhijitMuhurta}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
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
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getText('yama', lang)}: ${data.yamaGandam}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFFB71C1C), fontWeight: FontWeight.w500),
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
                    color: isToday ? const Color(0xFFE65100) : AppColors.maroonPrimary,
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
      ],
    );
  }

  // --- TAB 2: VEDIC MONTH CALENDAR ---
  Widget _buildCalendarTab(BuildContext context, PanchangaService service, String lang) {
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
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.maroonPrimary),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                });
              },
            ),
            Text(
              monthTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.maroonPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.maroonPrimary),
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
            childAspectRatio: 0.85,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.selectionClick();
                _showDayPanchangaPopup(context, day, service, lang);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: day.isToday
                      ? AppColors.maroonPrimary
                      : (day.isAuspicious ? const Color(0xFFFFF8E1) : const Color(0xFFFAF7F2)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: day.isToday
                        ? AppColors.goldPrimary
                        : (day.isAuspicious ? const Color(0xFFFFB300) : const Color(0xFFE8DECF)),
                    width: day.isToday || day.isAuspicious ? 1.4 : 0.8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: day.isToday ? Colors.white : const Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      day.tithi,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: day.isToday ? Colors.white70 : const Color(0xFF795548),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (day.festivalName != null) ...[
                      const SizedBox(height: 1),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: day.isToday ? Colors.amberAccent : const Color(0xFFE65100),
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

        // Festival Legend / List in this month
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
                    (lang == 'kn') ? 'ಈ ತಿಂಗಳ ಪವಿತ್ರ ವ್ರತಗಳು' : 'Vratas in this Month',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...days.where((d) => d.festivalName != null).map((d) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.maroonPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${d.day}',
                          style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${d.festivalName!} (${d.tithi})',
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

  void _showDayPanchangaPopup(BuildContext context, VedicDayInfo day, PanchangaService service, String lang) {
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
          side: const BorderSide(color: Color(0xFFECD7B8), width: 1.8),
        ),
        contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sacred Header with Saffron Sun
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8F00), Color(0xFFE65100)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE65100).withOpacity(0.3),
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
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.maroonPrimary,
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
                                color: AppColors.maroonPrimary,
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
            const Divider(color: Color(0xFFECD7B8), height: 1),
            const SizedBox(height: 12),

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
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroonPrimary,
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
                backgroundColor: AppColors.maroonPrimary,
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
  Widget _buildRashiChartTab(BuildContext context, PanchangaService service, String lang) {
    final rashis = service.getAllRashiDetails(lang);
    if (_selectedRashiIndex >= rashis.length) {
      _selectedRashiIndex = 0;
    }
    final selectedRashi = rashis[_selectedRashiIndex];

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    color: isSelected ? AppColors.maroonPrimary : const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.goldPrimary : const Color(0xFFE4D7C8),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.maroonPrimary.withOpacity(0.25),
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
                          color: isSelected ? AppColors.goldPrimary : const Color(0xFF5D4037),
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
            border: Border.all(color: const Color(0xFFECD7B8), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withOpacity(0.08),
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
                      color: AppColors.maroonPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        selectedRashi.symbol,
                        style: const TextStyle(fontSize: 22, color: AppColors.goldPrimary),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.maroonPrimary,
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
