import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

class InlineEditBar extends StatefulWidget {
  final CardGeneratorViewModel viewModel;

  const InlineEditBar({super.key, required this.viewModel});

  @override
  State<InlineEditBar> createState() => _InlineEditBarState();
}

class _InlineEditBarState extends State<InlineEditBar> {
  late TextEditingController _headlineCtrl;
  late TextEditingController _subtextCtrl;
  late TextEditingController _microCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.viewModel.cardData;
    _headlineCtrl = TextEditingController(text: d?.headline ?? '');
    _subtextCtrl = TextEditingController(text: d?.subtext ?? '');
    _microCtrl = TextEditingController(text: d?.microStat ?? '');
    widget.viewModel.addListener(_syncFromVm);
  }

  @override
  void didUpdateWidget(covariant InlineEditBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_syncFromVm);
      widget.viewModel.addListener(_syncFromVm);
    }
  }

  void _syncFromVm() {
    final d = widget.viewModel.cardData;
    if (d == null) return;
    // Avoid overwriting while user is typing — only sync if field lost focus and differs
    if (!_headlineCtrl.text.contains(d.headline) && _headlineCtrl.text != d.headline) {
      // sync only on external change (e.g., LLM polish) when controllers not focused
      final hasFocus = FocusManager.instance.primaryFocus?.context?.widget is EditableText;
      if (!hasFocus) {
        _headlineCtrl.text = d.headline;
        _subtextCtrl.text = d.subtext;
        _microCtrl.text = d.microStat ?? '';
      }
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncFromVm);
    _headlineCtrl.dispose();
    _subtextCtrl.dispose();
    _microCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, AppSpacing.sm, AppSpacing.screenHorizontal, AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_rounded, size: 13, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'EDIT TEXT',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (widget.viewModel.isExtracting)
                Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.8, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 6),
                    Text('Polishing…', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _Field(
            controller: _headlineCtrl,
            label: 'Headline — max 60',
            maxLen: 60,
            maxLines: 2,
            onChanged: (v) => widget.viewModel.updateHeadline(v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Field(
            controller: _subtextCtrl,
            label: 'Hook — one sentence, max 90',
            maxLen: 90,
            maxLines: 2,
            onChanged: (v) => widget.viewModel.updateSubtext(v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Field(
            controller: _microCtrl,
            label: 'Badge (optional) — e.g. Hat-trick • 90\'',
            maxLen: 24,
            maxLines: 1,
            onChanged: (v) => widget.viewModel.updateMicroStat(v),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLen;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.maxLen,
    required this.maxLines,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      maxLength: maxLen,
      maxLines: maxLines,
      minLines: 1,
      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm, borderSide: BorderSide(color: theme.colorScheme.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm, borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.7))),
        focusedBorder: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm, borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      onChanged: onChanged,
    );
  }
}
