import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_switch.dart';

import '../../view_models/card_generator_view_model.dart';

class BrandingPanel extends ConsumerStatefulWidget {
  const BrandingPanel({super.key});

  @override
  ConsumerState<BrandingPanel> createState() => _BrandingPanelState();
}

class _BrandingPanelState extends ConsumerState<BrandingPanel> {
  late TextEditingController _brandNameCtrl;
  late TextEditingController _brandHandleCtrl;
  late TextEditingController _watermarkCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(cardGeneratorViewModelProvider);
    _brandNameCtrl = TextEditingController(text: state.brandName ?? '');
    _brandHandleCtrl = TextEditingController(text: state.brandHandle ?? '');
    _watermarkCtrl = TextEditingController(text: state.watermarkText ?? '');
  }

  @override
  void dispose() {
    _brandNameCtrl.dispose();
    _brandHandleCtrl.dispose();
    _watermarkCtrl.dispose();
    super.dispose();
  }

  Future<ImageSource?> _pickImageSource(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);

    if (_brandNameCtrl.text != (state.brandName ?? '') &&
        !FocusScope.of(context).hasFocus) {
      _brandNameCtrl.text = state.brandName ?? '';
    }
    if (_brandHandleCtrl.text != (state.brandHandle ?? '') &&
        !FocusScope.of(context).hasFocus) {
      _brandHandleCtrl.text = state.brandHandle ?? '';
    }
    if (_watermarkCtrl.text != (state.watermarkText ?? '') &&
        !FocusScope.of(context).hasFocus) {
      _watermarkCtrl.text = state.watermarkText ?? '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _brandNameCtrl,
          decoration: InputDecoration(
            labelText: 'Brand / Account Name',
            hintText: 'e.g. Premier Central',
            border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm),
            isDense: true,
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
          ),
          onChanged: notifier.setBrandName,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _brandHandleCtrl,
          decoration: InputDecoration(
            labelText: 'Brand Handle',
            hintText: 'e.g. @premiercentral',
            border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusSm),
            isDense: true,
            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
          ),
          onChanged: notifier.setBrandHandle,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Show Card Brand Footer', style: theme.textTheme.titleSmall),
            AppSwitch(
              value: state.showBrandFooter,
              onChanged: notifier.setShowBrandFooter,
            ),
          ],
        ),
        const Divider(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Show Corner Watermark', style: theme.textTheme.titleSmall),
            AppSwitch(
              value: state.showWatermark,
              onChanged: notifier.setShowWatermark,
            ),
          ],
        ),
        if (state.showWatermark) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _watermarkCtrl,
            decoration: InputDecoration(
              labelText: 'Watermark Text',
              hintText: '@yourhandle',
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              isDense: true,
              prefixIcon: const Icon(
                Icons.branding_watermark_outlined,
                size: 20,
              ),
            ),
            onChanged: notifier.setWatermarkText,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(
                    state.watermarkImage == null
                        ? 'Upload Logo'
                        : 'Change Logo',
                  ),
                  onPressed: () async {
                    final source = await _pickImageSource(context);
                    if (source != null) {
                      await notifier.pickWatermarkImage(source);
                    }
                  },
                ),
              ),
              if (state.watermarkImage != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'Remove logo',
                  onPressed: notifier.removeWatermarkImage,
                ),
              ],
            ],
          ),
          if (state.watermarkImage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusSm,
              child: Image.file(
                state.watermarkImage!,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Size', style: theme.textTheme.labelMedium),
              Expanded(
                child: Semantics(
                  slider: true,
                  label: 'Watermark Size',
                  value: '${state.watermarkSize.round()}',
                  onIncrease: () {
                    final next = (state.watermarkSize + 8.0).clamp(24.0, 160.0);
                    notifier.setWatermarkSize(next);
                  },
                  onDecrease: () {
                    final next = (state.watermarkSize - 8.0).clamp(24.0, 160.0);
                    notifier.setWatermarkSize(next);
                  },
                  child: GestureDetector(
                    onDoubleTap: () {
                      Haptics.selectionClick();
                      notifier.setWatermarkSize(64.0);
                    },
                    child: Slider(
                      value: state.watermarkSize,
                      min: 24,
                      max: 160,
                      divisions: 17,
                      label: '${state.watermarkSize.round()}',
                      onChanged: notifier.setWatermarkSize,
                      onChangeEnd: (_) => Haptics.selectionClick(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tip: drag watermark on card to reposition. Snaps to center & margins.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
