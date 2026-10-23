import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon.dart';
import '../providers/nickname_provider.dart';

/// Text field + Save / Remove buttons for one Pokémon's nickname.
/// The nickname itself lives in [nicknamesProvider]; this widget only owns
/// the text controller for what the user is currently typing.
class NicknameEditor extends ConsumerStatefulWidget {
  const NicknameEditor({super.key, required this.pokemon});

  final Pokemon pokemon;

  @override
  ConsumerState<NicknameEditor> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends ConsumerState<NicknameEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(nicknamesProvider)[widget.pokemon.id];
    _controller = TextEditingController(text: saved ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    ref.read(nicknamesProvider.notifier).setNickname(widget.pokemon.id, value);
    FocusScope.of(context).unfocus();
    _showMessage('Nickname saved');
  }

  void _remove() {
    ref.read(nicknamesProvider.notifier).removeNickname(widget.pokemon.id);
    _controller.clear();
    FocusScope.of(context).unfocus();
    _showMessage('Nickname removed');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final saved =
        ref.watch(nicknamesProvider.select((n) => n[widget.pokemon.id]));
    final typed = _controller.text.trim();
    final canSave = typed.isNotEmpty && typed != saved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLength: 20,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: 'Nickname',
            hintText: 'Give ${widget.pokemon.displayName} a nickname',
            helperText: saved == null
                ? 'No nickname yet'
                : 'Current nickname: $saved',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: canSave ? _save : null,
              icon: const Icon(Icons.save_outlined),
              label: Text(saved == null ? 'Save nickname' : 'Update nickname'),
            ),
            if (saved != null)
              OutlinedButton.icon(
                onPressed: _remove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove nickname'),
              ),
          ],
        ),
      ],
    );
  }
}
