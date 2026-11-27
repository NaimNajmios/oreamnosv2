import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/services/club_profile_store.dart';
import '../../../../data/services/color_extractor.dart';
import '../../../../domain/models/club_profile.dart';

/// User-supplied club setup. No real clubs' crests or colours ship as assets.
class BrandKitScreen extends StatefulWidget {
  const BrandKitScreen({super.key});

  @override
  State<BrandKitScreen> createState() => _BrandKitScreenState();
}

class _BrandKitScreenState extends State<BrandKitScreen> {
  late final TextEditingController _name;
  late final TextEditingController _handle;
  late final TextEditingController _crest;
  late final ClubProfileStore _store;
  List<Color> _home = const [Color(0xFFFFD100), Color(0xFF003087)];
  List<RosterPlayer> _roster = const [];

  @override
  void initState() {
    super.initState();
    _store = getIt<ClubProfileStore>();
    final profile = _store.load();
    _name = TextEditingController(text: profile?.name ?? 'My Club');
    _handle = TextEditingController(text: profile?.handle ?? '');
    _crest = TextEditingController(text: profile?.crestPath ?? '');
    _home = profile?.homeColors ?? _home;
    _roster = profile?.roster ?? const [];
  }

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _crest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brand Kit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save club',
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Club name'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _handle,
            decoration: const InputDecoration(labelText: 'Handle'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _crest,
            decoration: const InputDecoration(
              labelText: 'Crest image path (your own file)',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Kit colours', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: [
              for (final swatch in ColorExtractor.presetSwatches)
                ChoiceChip(
                  label: Text(swatch.name),
                  selected: _home.first == swatch.colors.first,
                  onSelected: (_) =>
                      setState(() => _home = List.of(swatch.colors)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Roster (${_roster.length})',
                style: theme.textTheme.titleMedium,
              ),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add player'),
                onPressed: _addPlayer,
              ),
            ],
          ),
          for (var i = 0; i < _roster.length; i++)
            ListTile(
              title: Text(_roster[i].name),
              subtitle: Text(
                _roster[i].cutoutPath ?? _roster[i].photoPath ?? 'No image',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() {
                  _roster = [
                    for (var j = 0; j < _roster.length; j++)
                      if (j != i) _roster[j],
                  ];
                }),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addPlayer() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Player name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    setState(() {
      _roster = [..._roster, RosterPlayer(name: name)];
    });
  }

  Future<void> _save() async {
    final profile = ClubProfile(
      name: _name.text.trim().isEmpty ? 'My Club' : _name.text.trim(),
      handle: _handle.text.trim().isEmpty ? null : _handle.text.trim(),
      crestPath: _crest.text.trim().isEmpty ? null : _crest.text.trim(),
      homeColors: _home,
      roster: _roster,
    );
    await _store.save(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Brand kit saved')));
  }
}
