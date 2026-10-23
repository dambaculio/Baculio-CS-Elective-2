# Pokédex (CS Elective 2 · Midterm)

A Flutter Pokédex that shows Pokémon as trading cards. State is managed with
**Riverpod**.

## Features

- Pokémon list loaded from [PokéAPI](https://pokeapi.co) with loading, error
  and empty states
- Reload button (loading screen) and pull-to-refresh, both re-calling `fetch()`
- Nicknames: add, edit and remove (the nickname is the card title; the
  original name stays in the details under the photo)
- Favorites: heart on every card and a collapsible Favorites panel
- Type filter and search, with a way to clear them
- Light and dark mode

## Run it

```bash
flutter pub get
flutter run
flutter test
```

## Project structure

```
lib/
  main.dart                    App entry point (ProviderScope + themes)
  models/pokemon.dart          Pokémon data model
  services/pokemon_service.dart  PokéAPI requests
  providers/                   Riverpod state (all app logic lives here)
    pokemon_list_provider.dart   list, fetch(), loading / error state
    nickname_provider.dart       nicknames
    favorites_provider.dart      favorites + panel open/closed
    filter_provider.dart         search text, type filter, visible list
  screens/
    pokedex_screen.dart          home page
    pokemon_detail_screen.dart   card details + nickname editor
  widgets/                     reusable UI (cards, favorites panel, filters…)
  utils/                       small helpers (labels, navigation)
  theme/                       light / dark themes and type colors
```

## State management

Widgets only **watch** providers and **call methods** on them; the providers
hold the logic. Every state change creates a new object, so Riverpod rebuilds
only the widgets that depend on it.
