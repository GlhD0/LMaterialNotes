import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/label/label.dart';
import '../../../models/note/types/note_type.dart';
import '../../actions/notes/add.dart';
import '../../extensions/build_context_extension.dart';

/// Button of the side navigation to quickly create a rich text note.
///
/// If a [label] is provided, the created note is directly categorized with it.
class SideNavigationAddNoteButton extends ConsumerWidget {
  /// Default constructor.
  ///
  /// The created note is categorized with the [label], or left uncategorized if it is `null`.
  const SideNavigationAddNoteButton({super.key, this.label});

  /// The label to categorize the created note with, `null` to create a note without any label.
  final Label? label;

  /// Creates a note and opens its editor, after closing the navigation drawer.
  void onPressed(BuildContext context, WidgetRef ref) {
    // Close the navigation drawer
    Navigator.pop(context);

    addNote(context, ref, noteType: NoteType.richText, label: label);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = this.label;

    return IconButton(
      style: IconButton.styleFrom(
        // Blend the button into the destination as a simple trailing icon
        foregroundColor: colorScheme.onSurfaceVariant,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      tooltip: label == null ? context.l.tooltip_fab_add_note : context.l.tooltip_side_navigation_add_note_with_label,
      onPressed: () => onPressed(context, ref),
      icon: const Icon(Icons.add, size: 20),
    );
  }
}
