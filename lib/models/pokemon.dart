/// A single Pokémon entry shown in the Pokédex grid.
///
/// The PokéAPI list endpoint only returns `name` and `url` for each entry,
/// e.g. `{"name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/"}`.
/// The ID is read from the last segment of that URL, and the image URL is
/// built from the ID — so the whole grid needs only ONE network request.
class Pokemon {
  final int id;
  final String name;
  final String imageUrl;

  const Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
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

  /// "bulbasaur" -> "Bulbasaur", "mr-mime" -> "Mr Mime"
  String get displayName => name
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');

  /// 1 -> "#001"
  String get formattedId => '#${id.toString().padLeft(3, '0')}';
}