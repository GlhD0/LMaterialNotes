import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../models/label/label.dart';
import '../../navigation/navigation_routes.dart';
import '../../providers/labels/labels_navigation/labels_navigation_provider.dart';
import '../actions/labels/add.dart';
import '../constants/paddings.dart';
import '../constants/sizes.dart';
import '../extensions/build_context_extension.dart';
import '../preferences/preference_key.dart';
import '../widgets/asset.dart';
import 'widgets/side_navigation_add_note_button.dart';

/// Side navigation with the drawer.
class SideNavigation extends ConsumerStatefulWidget {
  /// Default constructor.
  const SideNavigation({super.key});

  @override
  ConsumerState<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends ConsumerState<SideNavigation> {
  /// Index of the destination to add a new label.
  static const int _newLabelIndex = 1;

  /// Index of the destination of the first label.
  static const int _firstLabelIndex = 2;

  /// Index of the currently selected drawer destination.
  late int index;

  /// The labels to display in the drawer and to navigate to.
  List<Label> get _labels => ref.read(labelsNavigationProvider).value ?? [];

  /// Index of the destination of the page to manage the labels.
  int get _manageLabelsIndex => _labels.length + _firstLabelIndex;

  /// Index of the destination of the archives page.
  int get _archivesIndex => _manageLabelsIndex + 1;

  /// Index of the destination of the bin page.
  int get _binIndex => _archivesIndex + 1;

  /// Index of the destination of the settings page.
  int get _settingsIndex => _binIndex + 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setIndex();
  }

  /// Sets the index of the navigation drawer.
  void setIndex() {
    final route = ModalRoute.of(context)?.settings.name;

    assert(route != null, 'Missing current route while navigating');
    route!;

    final enableLabels = PreferenceKey.enableLabels.preferenceOrDefault;

    if (enableLabels) {
      final labels = _labels;

      if (route == NavigationRoute.notes.name) {
        index = 0;
      } else if (route == NavigationRoute.labels.name) {
        index = _manageLabelsIndex;
      } else if (route == NavigationRoute.archives.name) {
        index = _archivesIndex;
      } else if (route == NavigationRoute.bin.name) {
        index = _binIndex;
      } else if (route == NavigationRoute.settings.name) {
        index = _settingsIndex;
      } else if (labels.isNotEmpty) {
        labels.forEachIndexed((i, label) {
          if (route == NavigationRoute.getLabelRouteName(label)) {
            index = i + _firstLabelIndex;
          }
        });
      } else {
        throw Exception('Unknown route when setting the side navigation index: $route');
      }
    } else {
      if (route == NavigationRoute.notes.name) {
        index = 0;
      } else if (route == NavigationRoute.archives.name) {
        index = 1;
      } else if (route == NavigationRoute.bin.name) {
        index = 2;
      } else if (route == NavigationRoute.settings.name) {
        index = 3;
      }
    }
  }

  /// Executes the action of the destination with the [selectedIndex].
  void onDestinationSelected(int selectedIndex) {
    final enableLabels = PreferenceKey.enableLabels.preferenceOrDefault;

    // The destination to add a label opens a dialog instead of navigating
    if (enableLabels && selectedIndex == _newLabelIndex) {
      addLabel(context, ref);

      return;
    }

    // Close the navigation drawer
    Navigator.pop(context);

    // If the new index is the same as the current one, no need to navigate
    if (index == selectedIndex) {
      return;
    }

    if (enableLabels) {
      final labels = _labels;

      if (selectedIndex == 0) {
        context.goNamed(NavigationRoute.notes.name);
      } else if (selectedIndex == _manageLabelsIndex) {
        context.goNamed(NavigationRoute.labels.name);
      } else if (selectedIndex == _archivesIndex) {
        context.goNamed(NavigationRoute.archives.name);
      } else if (selectedIndex == _binIndex) {
        context.goNamed(NavigationRoute.bin.name);
      } else if (selectedIndex == _settingsIndex) {
        context.goNamed(NavigationRoute.settings.name);
      } else if (labels.isNotEmpty) {
        labels.forEachIndexed((i, label) {
          if (selectedIndex == i + _firstLabelIndex) {
            context.goNamed(NavigationRoute.getLabelRouteName(label));
          }
        });
      } else {
        throw Exception('Unknown new side navigation index: $selectedIndex');
      }
    } else {
      switch (selectedIndex) {
        case 0:
          context.goNamed(NavigationRoute.notes.name);
        case 1:
          context.goNamed(NavigationRoute.archives.name);
        case 2:
          context.goNamed(NavigationRoute.bin.name);
        case 3:
          context.goNamed(NavigationRoute.settings.name);
        default:
          throw Exception('Unknown new side navigation index: $selectedIndex');
      }
    }

    setState(() {
      index = selectedIndex;
    });
  }

  /// Builds the label of a destination, followed by a [trailing] widget.
  ///
  /// The label of a destination occupies the space left by its icon, so the [trailing] widget
  /// is only displayed at the end of the destination by expanding the label to fill the remaining space.
  Widget _buildLabel({required String text, required Widget trailing, int maxLines = 1}) {
    return Expanded(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis),
          ),
          trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enableLabels = PreferenceKey.enableLabels.preferenceOrDefault;
    final labels = enableLabels ? (ref.watch(labelsNavigationProvider).value ?? <Label>[]) : <Label>[];

    return NavigationDrawer(
      onDestinationSelected: onDestinationSelected,
      selectedIndex: index,
      children: <Widget>[
        DrawerHeader(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(Asset.icon.path, fit: BoxFit.fitWidth, width: Sizes.appIcon.size),
              Padding(padding: Paddings.vertical(8)),
              Text(context.l.app_name, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.notes_outlined),
          selectedIcon: const Icon(Icons.notes),
          label: _buildLabel(text: context.l.navigation_notes, trailing: const SideNavigationAddNoteButton()),
        ),
        Divider(indent: 24, endIndent: 24),
        if (enableLabels) ...[
          NavigationDrawerDestination(icon: const Icon(Symbols.new_label), label: Text(context.l.navigation_new_label)),
          for (final label in labels)
            NavigationDrawerDestination(
              icon: Icon(label.pinned ? Icons.label_important_outline : Icons.label_outline, color: label.color),
              selectedIcon: Icon(label.pinned ? Icons.label_important : Icons.label, color: label.color),
              label: _buildLabel(
                text: label.name,
                maxLines: 2,
                trailing: SideNavigationAddNoteButton(label: label),
              ),
            ),
          NavigationDrawerDestination(
            icon: const Icon(Symbols.auto_label),
            selectedIcon: VariedIcon.varied(Symbols.auto_label, fill: 1.0),
            label: Text(context.l.navigation_manage_labels_destination),
          ),
          Divider(indent: 24, endIndent: 24),
        ],
        NavigationDrawerDestination(
          icon: const Icon(Icons.archive_outlined),
          selectedIcon: const Icon(Icons.archive),
          label: Text(context.l.navigation_archives),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.delete_outline),
          selectedIcon: const Icon(Icons.delete),
          label: Text(context.l.navigation_bin),
        ),
        Divider(indent: 24, endIndent: 24),
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(context.l.navigation_settings),
        ),
      ],
    );
  }
}
