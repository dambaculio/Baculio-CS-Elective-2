import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pokemon.dart';
import '../providers/pokemon_provider.dart';
import '../theme/pokemon_type_colors.dart';

class PokemonDetailScreen extends StatelessWidget {
  const PokemonDetailScreen({super.key, required this.pokemonId});

  final int pokemonId;

  @override
  Widget build(BuildContext context) {
    final pokemon = context.select<PokemonProvider, Pokemon?>(
      (provider) => provider.findById(pokemonId),
    );

    if (pokemon == null) {
      return const Scaffold(
        body: Center(child: Text('Pokémon not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(pokemon.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroSection(pokemon: pokemon),
                const SizedBox(height: 20),
                _InfoSection(
                  title: 'Pokédex data',
                  icon: Icons.straighten_outlined,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InfoTile(
                        label: 'Height',
                        value: pokemon.height == null
                            ? 'Unknown'
                            : '${(pokemon.height! / 10).toStringAsFixed(1)} m',
                      ),
                      _InfoTile(
                        label: 'Weight',
                        value: pokemon.weight == null
                            ? 'Unknown'
                            : '${(pokemon.weight! / 10).toStringAsFixed(1)} kg',
                      ),
                      _InfoTile(
                        label: 'Base EXP',
                        value: pokemon.baseExperience?.toString() ?? 'Unknown',
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
                      children: pokemon.abilities
                          .map((ability) => Chip(
                                label: Text(Pokemon.typeLabel(ability)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                if (pokemon.stats.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InfoSection(
                    title: 'Base stats',
                    icon: Icons.insights_outlined,
                    child: Column(
                      children: pokemon.stats
                          .map((stat) => _StatRow(stat: stat))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    final palette = PokemonTypeColors.paletteOf(pokemon.primaryType);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: palette.gradient),
        border: Border.all(color: palette.border, width: 2),
      ),
      child: Column(
        children: [
          Image.network(
            pokemon.imageUrl,
            height: 260,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image_not_supported_outlined,
              size: 96,
            ),
          ),
          Text(
            pokemon.displayName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            pokemon.formattedId,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (pokemon.types.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: pokemon.types
                  .map((type) => Chip(label: Text(Pokemon.typeLabel(type))))
                  .toList(),
            ),
          ],
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