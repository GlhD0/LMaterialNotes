import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/constants.dart';
import '../../../../common/constants/paddings.dart';
import '../../../../common/extensions/build_context_extension.dart';
import '../../../../models/note/note.dart';

/// Plain text editor.
class PlainTextEditor extends ConsumerStatefulWidget {
  /// Text editor allowing to edit the plain text content of a [PlainTextNote].
  const PlainTextEditor({
    super.key,
    required this.note,
    required this.readOnly,
    required this.autofocus,
    required this.onChanged,
  });

  /// The note to display.
  final PlainTextNote note;

  /// Whether the text fields are read only.
  final bool readOnly;

  /// Whether the text field should request focus.
  final bool autofocus;

  /// Called when the note has changed.
  final ValueChanged<Note> onChanged;

  @override
  ConsumerState<PlainTextEditor> createState() => _PlainTextEditorState();
}

class _PlainTextEditorState extends ConsumerState<PlainTextEditor> {
  late final TextEditingController contentTextController;

  /// Whether the spell check is enabled.
  ///
  /// The spell check is disabled for contents longer than [spellCheckContentLengthLimit],
  /// as it processes the whole content on each change.
  late bool spellCheckEnabled;

  @override
  void initState() {
    super.initState();

    contentTextController = TextEditingController(text: widget.note.content);
    spellCheckEnabled = widget.note.content.length <= spellCheckContentLengthLimit;
  }

  void onChanged() {
    final content = contentTextController.text;
    final note = widget.note..content = content;

    final newSpellCheckEnabled = content.length <= spellCheckContentLengthLimit;
    if (newSpellCheckEnabled != spellCheckEnabled) {
      setState(() {
        spellCheckEnabled = newSpellCheckEnabled;
      });
    }

    widget.onChanged(note);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Paddings.pageHorizontal,
      child: TextField(
        controller: contentTextController,
        focusNode: editorFocusNode,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        maxLines: null,
        expands: true,
        decoration: InputDecoration.collapsed(hintText: context.l.hint_content),
        spellCheckConfiguration: spellCheckEnabled
            ? SpellCheckConfiguration(spellCheckService: DefaultSpellCheckService())
            : const SpellCheckConfiguration.disabled(),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
