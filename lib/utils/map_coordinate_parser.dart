/// Parses coordinates from Google Maps links and manual coordinate text.
///
/// Supported examples:
/// - 4.1755, 73.5093
/// - 4.1755 73.5093
/// - https://www.google.com/maps?q=4.1755,73.5093
/// - https://www.google.com/maps/@4.1755,73.5093,17z
/// - Google Maps links containing !3d4.1755!4d73.5093
/// - DMS text like 4°10'31.8"N 73°30'33.5"E
///
/// Note: shortened links such as maps.app.goo.gl usually do not contain the
/// coordinates inside the text, so they cannot be parsed unless the full link
/// has already expanded to a URL that contains latitude and longitude.
(double, double)? parseMapCoordinates(String value) {
  var text = value.trim();
  if (text.isEmpty) return null;

  // Decode Google Maps URL encodings like %2C and keep trying a few times in
  // case the link was encoded more than once.
  for (var i = 0; i < 3; i++) {
    try {
      final decoded = Uri.decodeFull(text);
      if (decoded == text) break;
      text = decoded;
    } catch (_) {
      break;
    }
  }

  text = text.replaceAll('\u2212', '-');

  double? toDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim());
  }

  bool valid(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  (double, double)? fromMatch(Match? match) {
    if (match == null) return null;
    final lat = toDouble(match.group(1));
    final lng = toDouble(match.group(2));
    if (lat == null || lng == null || !valid(lat, lng)) return null;
    return (lat, lng);
  }

  const number = r'(-?\d{1,2}(?:\.\d+)?)';
  const longitude = r'(-?\d{1,3}(?:\.\d+)?)';

  final lngLatMatch = RegExp('!2d$longitude!3d$number', caseSensitive: false).firstMatch(text);
  if (lngLatMatch != null) {
    final lng = toDouble(lngLatMatch.group(1));
    final lat = toDouble(lngLatMatch.group(2));
    if (lat != null && lng != null && valid(lat, lng)) return (lat, lng);
  }

  final patterns = <RegExp>[
    // Common full Google Maps browser links.
    RegExp('@$number\\s*,\\s*$longitude', caseSensitive: false),
    RegExp(r'[?&](?:q|query|ll|sll|center|destination|daddr|origin)=\s*' '$number\\s*,\\s*$longitude', caseSensitive: false),

    // Google Maps place/data links often contain !3dLAT!4dLNG.
    RegExp('!3d$number!4d$longitude', caseSensitive: false),

    // Some links/text contain lat,lng without a parameter name.
    RegExp('$number\\s*,\\s*$longitude', caseSensitive: false),
    RegExp('$number\\s+,\\s*$longitude', caseSensitive: false),
    RegExp('$number\\s+$longitude', caseSensitive: false),
  ];

  for (final pattern in patterns) {
    final result = fromMatch(pattern.firstMatch(text));
    if (result != null) return result;
  }

  final dmsResult = _parseDmsCoordinates(text);
  if (dmsResult != null && valid(dmsResult.$1, dmsResult.$2)) {
    return dmsResult;
  }

  return null;
}

(double, double)? _parseDmsCoordinates(String text) {
  final dmsPattern = RegExp(
    r'''(\d{1,2})[°\s]+(\d{1,2})['’\s]+(\d{1,2}(?:\.\d+)?)?["”\s]*([NS])[^0-9A-Z]+(\d{1,3})[°\s]+(\d{1,2})['’\s]+(\d{1,2}(?:\.\d+)?)?["”\s]*([EW])''',
    caseSensitive: false,
  );
  final match = dmsPattern.firstMatch(text);
  if (match == null) return null;

  double convert(String deg, String min, String? sec, String direction) {
    var value = double.parse(deg) + double.parse(min) / 60 + (double.tryParse(sec ?? '0') ?? 0) / 3600;
    if (direction.toUpperCase() == 'S' || direction.toUpperCase() == 'W') {
      value = -value;
    }
    return value;
  }

  final lat = convert(match.group(1)!, match.group(2)!, match.group(3), match.group(4)!);
  final lng = convert(match.group(5)!, match.group(6)!, match.group(7), match.group(8)!);
  return (lat, lng);
}
