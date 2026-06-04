enum LiturgicalSeason {
  advent,
  christmas,
  epiphany,
  lent,
  holyWeek,
  goodFriday,
  easter,
  pentecost,
  ordinary,
}

DateTime westernGregorianEasterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

DateTime adventStart(int year) {
  final earliest = DateTime(year, 11, 27);
  final daysUntilSunday = DateTime.sunday - earliest.weekday;
  return earliest.add(Duration(days: daysUntilSunday));
}

LiturgicalSeason liturgicalSeasonFor(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final easter = westernGregorianEasterSunday(day.year);
  final ashWednesday = easter.subtract(const Duration(days: 46));
  final palmSunday = easter.subtract(const Duration(days: 7));
  final goodFriday = easter.subtract(const Duration(days: 2));
  final pentecost = easter.add(const Duration(days: 49));
  final advent = adventStart(day.year);
  final christmasStart = DateTime(day.year, 12, 25);
  final christmasEnd = DateTime(day.year + 1, 1, 5);
  final previousChristmasStart = DateTime(day.year - 1, 12, 25);
  final previousChristmasEnd = DateTime(day.year, 1, 5);
  final epiphany = DateTime(day.year, 1, 6);

  if (!_isBefore(day, previousChristmasStart) &&
      !_isAfter(day, previousChristmasEnd)) {
    return LiturgicalSeason.christmas;
  }
  if (!_isBefore(day, christmasStart) && !_isAfter(day, christmasEnd)) {
    return LiturgicalSeason.christmas;
  }
  if (!_isBefore(day, advent) && _isBefore(day, christmasStart)) {
    return LiturgicalSeason.advent;
  }
  if (!_isBefore(day, epiphany) && _isBefore(day, ashWednesday)) {
    return LiturgicalSeason.epiphany;
  }
  if (!_isBefore(day, ashWednesday) && _isBefore(day, palmSunday)) {
    return LiturgicalSeason.lent;
  }
  if (_isSameDay(day, goodFriday)) return LiturgicalSeason.goodFriday;
  if (!_isBefore(day, palmSunday) && _isBefore(day, easter)) {
    return LiturgicalSeason.holyWeek;
  }
  if (_isSameDay(day, pentecost)) return LiturgicalSeason.pentecost;
  if (!_isBefore(day, easter) && _isBefore(day, pentecost)) {
    return LiturgicalSeason.easter;
  }
  return LiturgicalSeason.ordinary;
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

bool _isBefore(DateTime first, DateTime second) {
  return first.compareTo(second) < 0;
}

bool _isAfter(DateTime first, DateTime second) {
  return first.compareTo(second) > 0;
}
