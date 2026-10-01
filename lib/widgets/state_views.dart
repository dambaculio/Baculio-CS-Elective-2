import 'package:flutter/material.dart';

/// Shown while the Future is in ConnectionState.waiting.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessage(
      icon: SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(strokeWidth: 4),
      ),
      title: 'Catching Pokémon…',
      subtitle: 'Fetching the first 30 entries from PokéAPI.',
    );
  }
}

/// Shown when the Future completed with an error.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icon(
        Icons.wifi_off_rounded,
        size: 56,
        color: Theme.of(context).colorScheme.error,
      ),
      title: 'Oops! The Pokémon got away.',
      subtitle: message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Try again'),
      ),
    );
  }
}

/// Shown when the Future completed with an empty list,
/// or when a search has no matches.
class EmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyView({
    super.key,
    this.title = 'No Pokémon found',
    this.subtitle = 'PokéAPI returned an empty list.',
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icon(
        Icons.catching_pokemon,
        size: 56,
        color: Theme.of(context).colorScheme.outline,
      ),
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}