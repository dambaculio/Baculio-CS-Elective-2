import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nicknames keyed by Pokémon id. The Pokémon's original name is never
/// changed; the UI shows the nickname next to it.
class NicknamesNotifier extends Notifier<Map<int, String>> {
  @override
  Map<int, String> build() => const <int, String>{};

  /// Adds or edits a nickname. A blank nickname removes it.
  void setNickname(int id, String nickname) {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      removeNickname(id);
      return;
    }
    // State is immutable: always assign a NEW map so listeners are notified.
    state = {...state, id: trimmed};
  }

  void removeNickname(int id) {
    if (!state.containsKey(id)) return;
    state = {...state}..remove(id);
  }
}

final nicknamesProvider =
    NotifierProvider<NicknamesNotifier, Map<int, String>>(
  NicknamesNotifier.new,
);
