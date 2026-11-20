import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    ref.watch(currentUserIdProvider);
    return const <int>{};
  }

  void toggle(int productId) {
    state = state.contains(productId)
        ? ({...state}..remove(productId))
        : {...state, productId};
  }

  void remove(int productId) {
    if (!state.contains(productId)) return;
    state = {...state}..remove(productId);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<int>>(
  FavoritesNotifier.new,
);
