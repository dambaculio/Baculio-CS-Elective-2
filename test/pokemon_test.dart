import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/models/pokemon.dart';
import 'package:flutter_application_1/screens/pokedex_screen.dart';
import 'package:flutter_application_1/services/pokemon_service.dart';

String _listBody(int count) => jsonEncode({
      'count': count,
      'results': List.generate(
        count,
        (i) => {
          'name': i == 0 ? 'bulbasaur' : 'pokemon-${i + 1}',
          'url': 'https://pokeapi.co/api/v2/pokemon/${i + 1}/',
        },
      ),
    });

Widget _app(http.Client client) => MaterialApp(
      home: PokedexScreen(service: PokemonService(client: client)),
    );

void main() {
  group('Pokemon model', () {
    test('parses id, name and image from a list entry', () {
      final p = Pokemon.fromJson({
        'name': 'mr-mime',
        'url': 'https://pokeapi.co/api/v2/pokemon/122/',
      });
      expect(p.id, 122);
      expect(p.displayName, 'Mr Mime');
      expect(p.formattedId, '#122');
      expect(p.imageUrl, endsWith('/122.png'));
    });

    test('throws FormatException on malformed data', () {
      expect(
        () => Pokemon.fromJson({'name': 'x'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PokemonService', () {
    test('requests limit=30 and returns 30 Pokémon', () async {
      late Uri requested;
      final client = MockClient((request) async {
        requested = request.url;
        return http.Response(_listBody(30), 200);
      });

      final result = await PokemonService(client: client).fetchPokemon();

      expect(requested.queryParameters['limit'], '30');
      expect(result, hasLength(30));
      expect(result.first.name, 'bulbasaur');
    });

    test('turns a non-200 response into PokemonServiceException', () async {
      final client = MockClient((_) async => http.Response('oops', 500));
      await expectLater(
        PokemonService(client: client).fetchPokemon(),
        throwsA(isA<PokemonServiceException>()),
      );
    });
  });

  group('PokedexScreen', () {
    testWidgets('shows loading, then the grid', (tester) async {
      await tester.pumpWidget(
        _app(MockClient((_) async => http.Response(_listBody(30), 200))),
      );
      expect(find.text('Catching Pokémon…'), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Bulbasaur'), findsOneWidget);
      expect(find.text('Showing 30 Pokémon'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        _app(MockClient((_) async => http.Response('down', 503))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('shows empty state when the API returns no results',
        (tester) async {
      await tester.pumpWidget(
        _app(MockClient((_) async => http.Response(_listBody(0), 200))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No Pokémon found'), findsOneWidget);
    });
  });
}