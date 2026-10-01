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
/// Fetching the list is a single HTTP GET: it produces exactly ONE result
/// (the list of 30 Pokémon) and then it is finished. "One result -> Future,
/// many results over time -> Stream" (Module 03 decision guide). There is no
/// continuous data here (no live feed, no WebSocket), so a Stream would add
/// complexity without any benefit.
class PokemonService {
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetches the first [limit] Pokémon. Defaults to 30 per the activity.
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

      return results
          .whereType<Map<String, dynamic>>()
          .map(Pokemon.fromJson)
          .take(limit)
          .toList();
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

  /// Releases the underlying HTTP connection pool.
  void dispose() => _client.close();
}