import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/models/pokemon.dart';
import 'package:flutter_application_1/providers/favorites_provider.dart';
import 'package:flutter_application_1/providers/filter_provider.dart';
import 'package:flutter_application_1/providers/nickname_provider.dart';
import 'package:flutter_application_1/providers/pokemon_list_provider.dart';
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

/// Same list response as above, plus a detail response that gives every
/// even-numbered Pokémon the "fire" type and every odd one "water".
http.Response _fakeApi(http.Request request) {
  if (request.url.path == '/api/v2/pokemon') {
    return http.Response(_listBody(30), 200);
  }
  final id = int.parse(request.url.pathSegments.last);
  return http.Response(
    jsonEncode({
      'types': [
        {
          'slot': 1,
          'type': {'name': id.isEven ? 'fire' : 'water'},
        },
      ],
      'height': 7,
      'weight': 69,
    }),
    200,
  );
}

ProviderScope _app(http.Client client) => ProviderScope(
      overrides: [
        pokemonServiceProvider.overrideWithValue(
          PokemonService(client: client),
        ),
      ],
      child: const MaterialApp(home: PokedexScreen()),
    );

Future<void> _loadHome(WidgetTester tester) async {
  await tester.pumpWidget(_app(MockClient((r) async => _fakeApi(r))));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

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
      late Uri listRequest;
      final client = MockClient((request) async {
        if (request.url.path == '/api/v2/pokemon') listRequest = request.url;
        return http.Response(_listBody(30), 200);
      });

      final result = await PokemonService(client: client).fetchPokemon();

      expect(listRequest.queryParameters['limit'], '30');
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

      // Title + the original name in the details area under the photo.
      expect(find.text('Bulbasaur'), findsWidgets);
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

  group('Riverpod state', () {
    test('NicknamesNotifier sets, edits and removes a nickname', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(nicknamesProvider.notifier);

      notifier.setNickname(1, '  Bulby ');
      expect(container.read(nicknamesProvider), {1: 'Bulby'});

      notifier.setNickname(1, 'Sprout');
      expect(container.read(nicknamesProvider)[1], 'Sprout');

      notifier.removeNickname(1);
      expect(container.read(nicknamesProvider), isEmpty);
    });

    test('FavoritesNotifier toggles favorites', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(favoritesProvider.notifier);

      notifier.toggle(25);
      expect(container.read(favoritesProvider), {25});

      notifier.toggle(25);
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('fetch() reloads the list and filter narrows it by type', () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          pokemonServiceProvider.overrideWithValue(
            PokemonService(
              client: MockClient((request) async {
                if (request.url.path == '/api/v2/pokemon') calls++;
                return _fakeApi(request);
              }),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pokemonListProvider.future);
      expect(calls, 1);

      await container.read(pokemonListProvider.notifier).fetch();
      expect(calls, 2);
      expect(container.read(pokemonListProvider).value, hasLength(30));
      expect(container.read(availableTypesProvider), ['fire', 'water']);

      container.read(pokemonFilterProvider.notifier).setType('fire');
      expect(container.read(visiblePokemonProvider), hasLength(15));

      container.read(pokemonFilterProvider.notifier).clearType();
      expect(container.read(visiblePokemonProvider), hasLength(30));
    });
  });

  group('Midterm features (widgets)', () {
    testWidgets('heart toggles favorite and the panel updates', (tester) async {
      await _loadHome(tester);

      // Open the panel: nothing is favorited yet.
      await tester.tap(find.byTooltip('Show favorites'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('No favorites yet'), findsOneWidget);

      // Favorite the first card.
      await tester.tap(find.byTooltip('Add to favorites').first);
      await tester.pump(const Duration(milliseconds: 400));

      // One heart on the card, one on the panel tile.
      expect(find.byTooltip('Remove from favorites'), findsNWidgets(2));
      expect(find.textContaining('No favorites yet'), findsNothing);
      expect(find.text('Favorites (1)'), findsOneWidget);

      // Un-favorite it again.
      await tester.tap(find.byTooltip('Remove from favorites').first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('No favorites yet'), findsOneWidget);
    });

    testWidgets('type filter shows matching Pokémon and can be cleared',
        (tester) async {
      await _loadHome(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Fire'));
      await tester.pump();
      expect(find.text('Showing 15 of 30 Pokémon'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pump();
      expect(find.text('Showing 30 Pokémon'), findsOneWidget);
    });

    testWidgets('nickname is the card title, original name stays in details',
        (tester) async {
      await _loadHome(tester);

      await tester.tap(find.text('Bulbasaur').first);
      await tester.pump(const Duration(milliseconds: 500));

      // The detail page has no Favorites button or panel.
      expect(find.byTooltip('Show favorites'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Bulby');
      await tester.pump();
      await tester.ensureVisible(find.text('Save nickname'));
      await tester.tap(find.text('Save nickname'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Original name'), findsOneWidget);
      expect(find.text('Bulbasaur'), findsOneWidget);

      // Back on the home page: nickname = title, original name in details.
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Bulby'), findsOneWidget);
      expect(find.text('Bulbasaur'), findsOneWidget);

      // Remove it again from the detail screen.
      await tester.tap(find.text('Bulby'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.ensureVisible(find.text('Remove nickname'));
      await tester.tap(find.text('Remove nickname'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('No nickname yet'), findsOneWidget);
    });

    testWidgets('reload button shows the loading screen, then the grid',
        (tester) async {
      await _loadHome(tester);
      expect(find.text('Catching Pokémon…'), findsNothing);

      await tester.tap(find.byTooltip('Reload'));
      await tester.pump();
      expect(find.text('Catching Pokémon…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Catching Pokémon…'), findsNothing);
      expect(find.text('Showing 30 Pokémon'), findsOneWidget);
    });
  });
}
