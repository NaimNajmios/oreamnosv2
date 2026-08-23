import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/settings_view_model.dart';
import 'widgets/add_pill_dialog.dart';

class PillManagerScreen extends StatelessWidget {
  const PillManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final pills = viewModel.customPills;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Refinement Pills'),
      ),
      body: pills.isEmpty
          ? Center(
              child: Text(
                'No custom pills added yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pills.length,
              itemBuilder: (context, index) {
                final pill = pills[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    title: Text(
                      pill.label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(pill.instruction),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        viewModel.removeCustomPill(pill);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddPillDialog.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
