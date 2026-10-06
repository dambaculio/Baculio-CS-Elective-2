/// A single Pokémon entry shown in the Pokédex grid.
///
/// The PokéAPI list endpoint only returns `name` and `url` for each entry,
/// e.g. `{"name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/"}`.
/// The ID is read from the last segment of that URL, and the image URL is
/// built from the ID. Types come from a second, per-Pokémon request
/// (see PokemonService).
class Pokemon {
  final int id;
  final String name;
  final String imageUrl;

  /// e.g. ['grass', 'poison']. Empty if the types could not be loaded.
  final List<String> types;
  final int? height;
  final int? weight;
  final int? baseExperience;
  final List<String> abilities;
  final List<PokemonStat> stats;

  const Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.types = const [],
    this.height,
    this.weight,
    this.baseExperience,
    this.abilities = const [],
    this.stats = const [],
  });

  static const String _artworkBase =
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork';

  /// Builds a [Pokemon] from one item of the API's `results` list.
  ///
  /// Uses `is` checks instead of blind `as` casts so malformed data throws a
  /// clear [FormatException] rather than a [TypeError] (see Module 02).
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final url = json['url'];

    if (name is! String || url is! String) {
      throw FormatException('Pokémon entry is missing "name" or "url": $json');
    }

    final segments =
        Uri.parse(url).pathSegments.where((s) => s.isNotEmpty).toList();
    final id = segments.isEmpty ? null : int.tryParse(segments.last);

    if (id == null) {
      throw FormatException('Could not read a Pokémon ID from "$url"');
    }

    return Pokemon(
      id: id,
      name: name,
      imageUrl: '$_artworkBase/$id.png',
    );
  }

  /// Reads the `types` field of a `/pokemon/{id}` response:
  /// `[{"slot": 1, "type": {"name": "grass"}}, ...]`
  /// Returns an empty list if the data isn't shaped as expected.
  static List<String> typesFromDetailJson(Object? json) {
    if (json is! List) return const [];
    final result = <String>[];
    for (final entry in json) {
      if (entry is! Map) continue;
      final type = entry['type'];
      if (type is! Map) continue;
      final name = type['name'];
      if (name is String) result.add(name);
    }
    return result;
  }

  static List<String> abilitiesFromDetailJson(Object? json) {
    if (json is! List) return const [];
    return [
      for (final entry in json)
        if (entry is Map && entry['ability'] is Map)
          if ((entry['ability'] as Map)['name'] is String)
            (entry['ability'] as Map)['name'] as String,
    ];
  }

  static List<PokemonStat> statsFromDetailJson(Object? json) {
    if (json is! List) return const [];
    return [
      for (final entry in json)
        if (entry is Map) PokemonStat.fromJson(entry),
    ];
  }

  Pokemon copyWith({
    List<String>? types,
    int? height,
    int? weight,
    int? baseExperience,
    List<String>? abilities,
    List<PokemonStat>? stats,
  }) => Pokemon(
        id: id,
        name: name,
        imageUrl: imageUrl,
        types: types ?? this.types,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        baseExperience: baseExperience ?? this.baseExperience,
        abilities: abilities ?? this.abilities,
        stats: stats ?? this.stats,
      );

  String? get primaryType => types.isEmpty ? null : types.first;
  String? get secondaryType => types.length > 1 ? types[1] : null;

  /// "grass" -> "Grass"
  static String typeLabel(String type) =>
      type.isEmpty ? type : type[0].toUpperCase() + type.substring(1);

  /// "bulbasaur" -> "Bulbasaur", "mr-mime" -> "Mr Mime"
  String get displayName => name
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');

  /// 1 -> "#001"
  String get formattedId => '#${id.toString().padLeft(3, '0')}';
}

class PokemonStat {
  final String name;
  final int value;

  const PokemonStat({required this.name, required this.value});

  factory PokemonStat.fromJson(Map<dynamic, dynamic> json) {
    final stat = json['stat'];
    final name = stat is Map && stat['name'] is String ? stat['name'] as String : '';
    final value = json['base_stat'];
    return PokemonStat(
      name: name,
      value: value is int ? value : int.tryParse('$value') ?? 0,
    );
  }

  String get displayName => name
      .split('-')
      .map((part) => part.isEmpty ? part : part[0].toUpperCase() + part.substring(1))
      .join(' ');
}