import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/liturgical_season.dart';

void main() {
  test('western Gregorian Easter Sunday is calculated for known years', () {
    expect(westernGregorianEasterSunday(2024), DateTime(2024, 3, 31));
    expect(westernGregorianEasterSunday(2025), DateTime(2025, 4, 20));
    expect(westernGregorianEasterSunday(2026), DateTime(2026, 4, 5));
  });

  test('liturgical season follows Western Gregorian calendar boundaries', () {
    expect(
      liturgicalSeasonFor(DateTime(2026, 6, 4)),
      LiturgicalSeason.ordinary,
    );
    expect(
      liturgicalSeasonFor(DateTime(2026, 11, 29)),
      LiturgicalSeason.advent,
    );
    expect(
      liturgicalSeasonFor(DateTime(2026, 12, 25)),
      LiturgicalSeason.christmas,
    );
    expect(
      liturgicalSeasonFor(DateTime(2026, 1, 6)),
      LiturgicalSeason.epiphany,
    );
    expect(liturgicalSeasonFor(DateTime(2026, 2, 18)), LiturgicalSeason.lent);
    expect(
      liturgicalSeasonFor(DateTime(2026, 3, 29)),
      LiturgicalSeason.holyWeek,
    );
    expect(
      liturgicalSeasonFor(DateTime(2026, 4, 3)),
      LiturgicalSeason.goodFriday,
    );
    expect(liturgicalSeasonFor(DateTime(2026, 4, 5)), LiturgicalSeason.easter);
    expect(
      liturgicalSeasonFor(DateTime(2026, 5, 24)),
      LiturgicalSeason.pentecost,
    );
  });
}
