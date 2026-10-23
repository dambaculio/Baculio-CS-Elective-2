import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/nickname_provider.dart';
import '../providers/pokemon_list_provider.dart';
import '../theme/pokemon_type_colors.dart';
import '../utils/pokemon_labels.dart';
import '../widgets/nickname_editor.dart';
import '../widgets/pokemon_card_parts.dart';

class PokemonDetailScreen extends ConsumerWidget {
  const PokemonDetailScreen({super.key, required this.pokemonId});

  final int pokemonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemon = ref.watch(pokemonByIdProvider(pokemonId));

    if (pokemon == null) {
      return const Scaffold(
        body: Center(child: Text('Pokémon not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Card details')),
      body: _DetailBody(pokemon: pokemon),
    );
  }
}

/// Scrollable body of the detail page: the card, the nickname editor and the
/// extra Pokédex data.
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroSection(pokemon: pokemon),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Nickname',
                icon: Icons.edit_outlined,
                child: NicknameEditor(pokemon: pokemon),
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Pokédex data',
                icon: Icons.straighten_outlined,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoTile(label: 'Height', value: pokemon.heightLabel),
                    _InfoTile(label: 'Weight', value: pokemon.weightLabel),
                    _InfoTile(
                      label: 'Base EXP',
                      value: pokemon.baseExperience?.toString() ?? '—',
                    ),
                  ],
                ),
              ),
              if (pokemon.abilities.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Abilities',
                  icon: Icons.auto_awesome_outlined,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final ability in pokemon.abilities)
                        Chip(label: Text(Pokemon.typeLabel(ability))),
                    ],
                  ),
                ),
              ],
              if (pokemon.stats.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Base stats',
                  icon: Icons.insights_outlined,
                  child: Column(
                    children: [
                      for (final stat in pokemon.stats) _StatRow(stat: stat),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Same card language as the grid: nickname as the title, photo with type
/// badge and heart, original name in the details below the photo.
class _HeroSection extends ConsumerWidget {
  const _HeroSection({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(nicknamesProvider.select((n) => n[pokemon.id]));
    final palette = PokemonTypeColors.paletteOf(pokemon.primaryType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
        border: Border.all(color: palette.border, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nickname ?? pokemon.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: pokemonInk,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          PokemonArtFrame(pokemon: pokemon, height: 280, heartSize: 40),
          const SizedBox(height: 12),
          PokemonDetailsStrip(pokemon: pokemon, compact: false),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final PokemonStat stat;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              stat.displayName,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${stat.value}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: (stat.value / 255).clamp(0, 1).toDouble(),
                color: color,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}