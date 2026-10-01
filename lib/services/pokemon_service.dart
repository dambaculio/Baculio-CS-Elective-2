import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

/// A user-friendly error the UI can show directly.
class PokemonServiceException implements Exception {
  final String message;
  const PokemonServiceException(this.message);

  @override
  String toString() => message;
}

/// Handles all API calls to PokéAPI.
///
/// WHY A FUTURE (not a Stream)?
/// Loading the Pokédex produces exactly ONE result (the list of 30 Pokémon,
/// each with its types) and then it is finished. "One result -> Future,
/// many results over time -> Stream" (Module 03 decision guide). There is no
/// continuous data here, so a Stream would add complexity without any benefit.
///
/// HOW IT LOADS:
/// 1. One request for the list (name + url).
/// 2. 30 independent detail requests for the types, run at the same time
///    with Future.wait() instead of one after another (Module 02).
class PokemonService {
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetches the first [limit] Pokémon with their types.
  Future<List<Pokemon>> fetchPokemon({int limit = 30}) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {'limit': '$limit', 'offset': '0'},
    );

    try {
      // Always set a timeout on network calls (Module 02 · Error Handling).
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        throw PokemonServiceException(
          'PokéAPI responded with status ${response.statusCode}. '
          'Please try again later.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object at the top level.');
      }

      final results = decoded['results'];
      if (results is! List) {
        throw const FormatException('Expected a "results" list.');
      }

      final basics = results
          .whereType<Map<String, dynamic>>()
          .map(Pokemon.fromJson)
          .take(limit)
          .toList();

      // Independent calls -> run concurrently. _withTypes never throws, so one
      // failed detail request can't reject the whole Future.wait().
      return await Future.wait(basics.map(_withTypes));
    } on PokemonServiceException {
      rethrow; // already user-friendly
    } on TimeoutException {
      throw const PokemonServiceException(
        'The request timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      // On mobile the http package wraps SocketException in ClientException;
      // on the web it is thrown for failed/CORS-blocked requests.
      throw const PokemonServiceException(
        'Could not reach PokéAPI. Check your internet connection.',
      );
    } on FormatException {
      throw const PokemonServiceException(
        'Received unexpected data from PokéAPI.',
      );
    } catch (e) {
      // Fallback for anything else — never swallow errors silently.
      throw PokemonServiceException('Something went wrong: $e');
    }
  }

  /// Loads the types of one Pokémon. Types are a nice-to-have, so on ANY
  /// failure we return the Pokémon without types (the card then uses neutral
  /// colors) instead of failing the whole list.
  Future<Pokemon> _withTypes(Pokemon pokemon) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/${pokemon.id}'))
          .timeout(_timeout);
      if (response.statusCode != 200) return pokemon;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return pokemon;

      return pokemon.copyWith(
        types: Pokemon.typesFromDetailJson(decoded['types']),
      );
    } catch (_) {
      return pokemon;
    }
  }

  /// Releases the underlying HTTP connection pool.
  void dispose() => _client.close();
}