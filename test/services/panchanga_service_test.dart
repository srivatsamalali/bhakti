import 'package:flutter_test/flutter_test.dart';
import 'package:bhakti/services/panchanga/panchanga_service.dart';

void main() {
  group('PanchangaService Real-time Astronomical Calculation Tests', () {
    late PanchangaService service;

    setUp(() {
      service = PanchangaService();
    });

    test('September 29, 2026 is Tuesday Angarki Sankashti Chaturthi', () {
      final data = service.getPanchangaForDate(DateTime(2026, 9, 29, 20, 0), 'en');
      expect(data.dayOfWeek, contains('Tuesday'));
      expect(data.tithi, contains('Chaturthi'));
      expect(data.specialOccasion, contains('Angarki Sankashti'));
    });

    test('September 30, 2026 is Wednesday Budhavara and NOT Sankashti today', () {
      final data = service.getPanchangaForDate(DateTime(2026, 9, 30, 8, 8), 'en');
      expect(data.dayOfWeek, contains('Wednesday'));
      expect(data.deityOfTheDay, contains('Krishna & Vitthala'));
      expect(data.specialOccasion, contains('Wednesday'));
      expect(data.specialOccasion, isNot(contains('Angarki Sankashti')));

      // In upcoming festivals, Sankashti should not be marked as 0 days / today
      for (final f in data.upcomingFestivals) {
        if (f.name.contains('Sankashti')) {
          expect(f.daysRemaining, greaterThan(0));
        }
      }
    });

    test('Kannada localization test for Panchanga on Sep 30, 2026', () {
      final data = service.getPanchangaForDate(DateTime(2026, 9, 30, 8, 8), 'kn');
      expect(data.dayOfWeek, 'ಬುಧವಾರ');
      expect(data.paksha, 'ಕೃಷ್ಣ ಪಕ್ಷ');
      expect(data.deityOfTheDay, contains('ಶ್ರೀ ಕೃಷ್ಣ'));
      expect(data.upcomingFestivals, isNotEmpty);
    });

    test('All 5 languages load correctly without errors', () {
      final now = DateTime(2026, 9, 30, 8, 8);
      for (final lang in ['kn', 'hi', 'ta', 'ml', 'en']) {
        final data = service.getPanchangaForDate(now, lang);
        expect(data.tithi, isNotEmpty);
        expect(data.paksha, isNotEmpty);
        expect(data.nakshatra, isNotEmpty);
        expect(data.yoga, isNotEmpty);
        expect(data.karana, isNotEmpty);
        expect(data.dayOfWeek, isNotEmpty);
        expect(data.deityOfTheDay, isNotEmpty);
        expect(data.upcomingFestivals, isNotEmpty);
      }
    });

    test('Dynamic Rashi Bhavishya updates per day and language', () {
      final wednesday = DateTime(2026, 9, 30); // Wednesday
      final thursday = DateTime(2026, 10, 1); // Thursday

      final rashisWed = service.getAllRashiDetails('kn', date: wednesday);
      final rashisThu = service.getAllRashiDetails('kn', date: thursday);

      expect(rashisWed.length, 12);
      expect(rashisThu.length, 12);

      // Predictions change dynamically across days
      expect(rashisWed.first.prediction, isNot(equals(rashisThu.first.prediction)));
      expect(rashisWed.first.prediction, isNotEmpty);
      expect(rashisWed.first.luckyColor, isNotEmpty);
      expect(rashisWed.first.luckyNumber, isNotEmpty);
      expect(rashisWed.first.mantra, isNotEmpty);
    });

    test('Calendar Days detect Amavasye, Hunnime, and Grahana', () {
      final days = service.getMonthCalendarDays(DateTime(2026, 9, 1), 'kn');
      expect(days, isNotEmpty);

      final hasAmavasya = days.any((d) => d.isAmavasya || d.tithi.contains('ಅಮಾವಾಸ್ಯೆ'));
      final hasHunnime = days.any((d) => d.isHunnime || d.tithi.contains('ಹುಣ್ಣಿಮೆ') || d.tithi.contains('ಪೌರ್ಣಮಿ'));
      
      expect(hasAmavasya, isTrue);
      expect(hasHunnime, isTrue);

      // Check Grahana on eclipse date (March 3, 2026 Lunar eclipse)
      final marchDays = service.getMonthCalendarDays(DateTime(2026, 3, 1), 'kn');
      final eclipseDay = marchDays.firstWhere((d) => d.day == 3);
      expect(eclipseDay.isGrahana, isTrue);
      expect(eclipseDay.grahanaName, isNotNull);
    });
  });
}
