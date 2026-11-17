import 'dart:ui';

/// Display names for the continent ids used in the map data.
const continentNames = <String, String>{
  'africa': 'Africa',
  'asia': 'Asia',
  'europe': 'Europe',
  'north_america': 'North America',
  'south_america': 'South America',
  'oceania': 'Australia & Oceania',
};

class MapCountry {
  const MapCountry({
    required this.id,
    required this.name,
    required this.continent,
    required this.polys,
  });

  final String id; // ISO-style code, e.g. LKA
  final String name;
  final String continent; // key of continentNames
  final List<List<Offset>> polys; // x: 0..1 (map width), y: 0..aspect

  factory MapCountry.fromJson(Map<String, dynamic> json) {
    return MapCountry(
      id: json['id'] as String,
      name: json['name'] as String,
      continent: json['continent'] as String,
      polys: [
        for (final raw in json['polys'] as List)
          _toPoints((raw as List).cast<num>()),
      ],
    );
  }

  static List<Offset> _toPoints(List<num> flat) => [
        for (var i = 0; i + 1 < flat.length; i += 2)
          Offset(flat[i].toDouble(), flat[i + 1].toDouble()),
      ];
}

/// Simplified world map (Mercator, Natural Earth 1:110m, public domain).
class WorldMap {
  const WorldMap({required this.aspect, required this.countries});

  final double aspect; // map height / map width
  final List<MapCountry> countries;

  factory WorldMap.fromJson(Map<String, dynamic> json) {
    return WorldMap(
      aspect: (json['aspect'] as num).toDouble(),
      countries: [
        for (final c in json['countries'] as List)
          MapCountry.fromJson(c as Map<String, dynamic>),
      ],
    );
  }
}

class MapPinQuestion {
  const MapPinQuestion({
    required this.prompt,
    required this.target,
    required this.hints,
  });

  final String prompt;
  final String target; // continent id or country id, depending on mode
  final List<String> hints;

  factory MapPinQuestion.fromJson(Map<String, dynamic> json) {
    return MapPinQuestion(
      prompt: json['prompt'] as String,
      target: json['target'] as String,
      hints: List<String>.from((json['hints'] as List?) ?? const []),
    );
  }
}

class MapPinLevel {
  const MapPinLevel({required this.mode, required this.questions});

  final String mode; // 'continent' or 'country'
  final List<MapPinQuestion> questions;

  bool get isCountryMode => mode == 'country';

  factory MapPinLevel.fromJson(Map<String, dynamic> json) {
    return MapPinLevel(
      mode: json['mode'] as String? ?? 'continent',
      questions: [
        for (final q in json['questions'] as List)
          MapPinQuestion.fromJson(q as Map<String, dynamic>),
      ],
    );
  }
}
