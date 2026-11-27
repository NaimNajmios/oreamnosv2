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
  late final TextEditingController _font;
  late final ClubProfileStore _store;
  late List<Color> _home;
  late List<Color> _away;
  late List<Color> _third;
  late String _lockup;
  late List<RosterPlayer> _roster;

  @override
  void initState() {
    super.initState();
    _store = getIt<ClubProfileStore>();
    final profile = _store.load();
    _name = TextEditingController(text: profile?.name ?? 'My Club');
    _handle = TextEditingController(text: profile?.handle ?? '');
    _crest = TextEditingController(text: profile?.crestPath ?? '');
    _font = TextEditingController(text: profile?.fontFamily ?? '');
    _home = profile?.homeColors ?? const [Color(0xFFFFD100), Color(0xFF003087)];
    _away = profile?.awayColors ?? const [Color(0xFFFFFFFF), Color(0xFFB0BEC5)];
    _third =
        profile?.thirdColors ?? const [Color(0xFF1B5E20), Color(0xFF2E7D32)];
    _lockup = profile?.lockupPosition ?? 'bottomLeft';
    _roster = profile?.roster ?? const [];
  }

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _crest.dispose();
    _font.dispose();
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
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _font,
            decoration: const InputDecoration(
              labelText: 'Font family override (optional)',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Lockup', style: theme.textTheme.titleSmall),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _lockup,
                onChanged: (v) {
                  if (v != null) setState(() => _lockup = v);
                },
                items: const [
                  DropdownMenuItem(
                    value: 'bottomLeft',
                    child: Text('Bottom left'),
                  ),
                  DropdownMenuItem(
                    value: 'bottomRight',
                    child: Text('Bottom right'),
                  ),
                  DropdownMenuItem(value: 'topLeft', child: Text('Top left')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Kit colours', style: theme.textTheme.titleMedium),
          _colourPicker('Home', _home, (c) => setState(() => _home = c)),
          _colourPicker('Away', _away, (c) => setState(() => _away = c)),
          _colourPicker('Third', _third, (c) => setState(() => _third = c)),
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

  Widget _colourPicker(
    String label,
    List<Color> selected,
    ValueChanged<List<Color>> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final swatch in ColorExtractor.presetSwatches)
                ChoiceChip(
                  label: Text(swatch.name),
                  selected: selected.first == swatch.colors.first,
                  onSelected: (_) => onChanged(List.of(swatch.colors)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addPlayer() async {
    final nameCtrl = TextEditingController();
    final photoCtrl = TextEditingController();
    final cutoutCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: photoCtrl,
              decoration: const InputDecoration(labelText: 'Photo path'),
            ),
            TextField(
              controller: cutoutCtrl,
              decoration: const InputDecoration(labelText: 'Cutout PNG path'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (saved == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _roster = [
          ..._roster,
          RosterPlayer(
            name: nameCtrl.text.trim(),
            photoPath: photoCtrl.text.trim().isEmpty
                ? null
                : photoCtrl.text.trim(),
            cutoutPath: cutoutCtrl.text.trim().isEmpty
                ? null
                : cutoutCtrl.text.trim(),
          ),
        ];
      });
    }
    nameCtrl.dispose();
    photoCtrl.dispose();
    cutoutCtrl.dispose();
  }

  Future<void> _save() async {
    final profile = ClubProfile(
      name: _name.text.trim().isEmpty ? 'My Club' : _name.text.trim(),
      handle: _handle.text.trim().isEmpty ? null : _handle.text.trim(),
      crestPath: _crest.text.trim().isEmpty ? null : _crest.text.trim(),
      fontFamily: _font.text.trim().isEmpty ? null : _font.text.trim(),
      lockupPosition: _lockup,
      homeColors: _home,
      awayColors: _away,
      thirdColors: _third,
      roster: _roster,
    );
    await _store.save(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Brand kit saved')));
  }
}
