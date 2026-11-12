import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/app_chip.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';

/// Page avatar shared by the composer header, preview card and success view.
/// Uses the Graph `picture` when available and falls back to the initial.
class FacebookPageAvatar extends StatelessWidget {
  const FacebookPageAvatar({
    super.key,
    required this.pageName,
    this.pictureUrl,
    this.size = 40,
  });

  final String pageName;
  final String? pictureUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = pictureUrl ?? '';
    final trimmedName = pageName.trim();
    final initial = trimmedName.isEmpty
        ? null
        : trimmedName.substring(0, 1).toUpperCase();

    Widget fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
      child: initial == null
          ? Icon(
              Icons.facebook_rounded,
              size: size * 0.52,
              color: theme.colorScheme.primary,
            )
          : Text(
              initial,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// Page identity + audience line — the Facebook composer's "posting as" row.
class PageIdentityRow extends StatelessWidget {
  const PageIdentityRow({
    super.key,
    required this.pageName,
    required this.pagePictureUrl,
    required this.needsConnection,
    required this.onTap,
  });

  final String pageName;
  final String pagePictureUrl;
  final bool needsConnection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = pageName.isNotEmpty && !needsConnection;
    final label = connected
        ? pageName
        : (pageName.isEmpty ? 'Connect your Page' : 'Reconnect your Page');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              FacebookPageAvatar(
                pageName: pageName,
                pictureUrl: pagePictureUrl,
                size: 42,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          needsConnection
                              ? Icons.warning_amber_rounded
                              : Icons.public_rounded,
                          size: 12,
                          color: needsConnection
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          needsConnection ? 'Action needed' : 'Public · Now',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: needsConnection
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                needsConnection
                    ? Icons.settings_rounded
                    : Icons.unfold_more_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Facebook-style media bar under the composer text.
class MediaActionBar extends StatelessWidget {
  const MediaActionBar({
    super.key,
    required this.onGallery,
    required this.onCamera,
    required this.onHashtags,
    this.hashtagsEnabled = true,
    this.mediaCount = 0,
    this.canAddPhoto = true,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onHashtags;
  final bool hashtagsEnabled;
  final int mediaCount;
  final bool canAddPhoto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MediaAction(
            icon: Icons.photo_library_outlined,
            label: canAddPhoto && mediaCount > 0
                ? 'Photo · $mediaCount/${FacebookLimits.maxPhotos}'
                : 'Photo',
            onTap: canAddPhoto ? onGallery : null,
          ),
        ),
        Expanded(
          child: _MediaAction(
            icon: Icons.photo_camera_outlined,
            label: 'Camera',
            onTap: onCamera,
          ),
        ),
        Expanded(
          child: _MediaAction(
            icon: Icons.tag_rounded,
            label: 'Hashtags',
            onTap: hashtagsEnabled ? onHashtags : null,
          ),
        ),
      ],
    );
  }
}

class _MediaAction extends StatelessWidget {
  const _MediaAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onTap == null
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              Haptics.lightImpact();
              onTap?.call();
            },
      borderRadius: AppSpacing.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crop preset chips. The selection drives both the preview frame and the
/// actual uploaded pixel crop.
class AspectSelector extends StatelessWidget {
  const AspectSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FacebookImageAspect selected;
  final ValueChanged<FacebookImageAspect> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.crop_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Crop',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            Text(
              'Drag to reposition · pinch to zoom',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final aspect in FacebookImageAspect.values)
              AppChip(
                label: '${aspect.label} · ${aspect.detail}',
                selected: aspect == selected,
                onTap: () => onSelected(aspect),
              ),
          ],
        ),
      ],
    );
  }
}

/// Zoom slider for the attached photo (accessibility alternative to pinch).
class CropZoomSlider extends StatelessWidget {
  const CropZoomSlider({
    super.key,
    required this.zoom,
    required this.onChanged,
    required this.onReset,
  });

  final double zoom;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.zoom_out_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        Expanded(
          child: Slider(
            value: zoom.clamp(1.0, 4.0),
            min: 1,
            max: 4,
            divisions: 30,
            label: '${zoom.toStringAsFixed(1)}×',
            onChanged: onChanged,
          ),
        ),
        Icon(
          Icons.zoom_in_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        IconButton(
          tooltip: 'Reset crop',
          onPressed: zoom <= 1.0 ? null : onReset,
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
        ),
      ],
    );
  }
}

/// Swipeable multi-photo preview with per-photo edit/remove and a cover
/// badge. Crop/alt editing happens in the "Edit photo" sheet so gestures
/// never fight the PageView.
class MediaCarousel extends StatefulWidget {
  const MediaCarousel({
    super.key,
    required this.media,
    required this.onEdit,
    required this.onRemove,
    this.onPageChanged,
  });

  final List<FacebookMediaItem> media;
  final ValueChanged<FacebookMediaItem> onEdit;
  final ValueChanged<String> onRemove;
  final ValueChanged<int>? onPageChanged;

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant MediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.media.length) {
      _index = widget.media.isEmpty ? 0 : widget.media.length - 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final current = widget.media[_index.clamp(0, widget.media.length - 1)];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: current.aspect.ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.media.length,
                onPageChanged: (index) {
                  setState(() => _index = index);
                  widget.onPageChanged?.call(index);
                  final item = widget.media[index];
                  SemanticsService.sendAnnouncement(
                    View.of(context),
                    'Photo ${index + 1} of ${widget.media.length}',
                    Directionality.of(context),
                  );
                  // Keep the frame in sync with the visible photo's aspect.
                  if (item.aspect != current.aspect) setState(() {});
                },
                itemBuilder: (context, index) {
                  final item = widget.media[index];
                  return PreviewImage(
                    imagePath: item.path,
                    aspect: item.aspect,
                    zoom: item.zoom,
                    offset: item.offset,
                    interactive: false,
                  );
                },
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: _Pill(label: '${_index + 1}/${widget.media.length}'),
              ),
              if (_index == 0)
                const Positioned(
                  bottom: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: _Pill(label: 'Cover'),
                ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Row(
                  children: [
                    _OverlayButton(
                      icon: Icons.tune_rounded,
                      tooltip: 'Edit photo ${_index + 1}',
                      onTap: () => widget.onEdit(current),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _OverlayButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Remove photo ${_index + 1}',
                      onTap: () => widget.onRemove(current.identity),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.media.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.media.length; i++)
                AnimatedContainer(
                  duration: AppMotion.transitionSpec,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: i == _index ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Full-bleed preview image with replace/remove overlays and optional
/// pinch/drag crop editing. The transform mirrors
/// `FacebookImageCropper.cropRectFor` so the upload matches the preview.
class PreviewImage extends StatefulWidget {
  const PreviewImage({
    super.key,
    required this.imagePath,
    required this.aspect,
    this.onReplace,
    this.onRemove,
    this.zoom = 1.0,
    this.offset = Offset.zero,
    this.onCropChanged,
    this.interactive = true,
  });

  final String imagePath;
  final FacebookImageAspect aspect;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;
  final double zoom;
  final Offset offset;
  final void Function(double zoom, Offset offset)? onCropChanged;
  final bool interactive;

  @override
  State<PreviewImage> createState() => _PreviewImageState();
}

class _PreviewImageState extends State<PreviewImage> {
  late double _startZoom;
  late Offset _startOffset;
  late Offset _startFocal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zoom = widget.zoom.clamp(1.0, 4.0).toDouble();
    final canCrop = widget.interactive && widget.onCropChanged != null;

    return AspectRatio(
      aspectRatio: widget.aspect.ratio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frame = Size(constraints.maxWidth, constraints.maxHeight);
          final panX = frame.width * (1 - 1 / zoom) / 2;
          final panY = frame.height * (1 - 1 / zoom) / 2;

          Widget image = Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scaleByDouble(zoom, zoom, 1, 1)
                ..translateByDouble(
                  -widget.offset.dx.clamp(-1.0, 1.0) * panX / zoom,
                  -widget.offset.dy.clamp(-1.0, 1.0) * panY / zoom,
                  0,
                  1,
                ),
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
                width: frame.width,
                height: frame.height,
                cacheWidth:
                    (frame.width * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                errorBuilder: (_, _, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Image unavailable — re-attach',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          if (canCrop) {
            image = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                _startZoom = zoom;
                _startOffset = widget.offset;
                _startFocal = details.focalPoint;
              },
              onScaleUpdate: (details) {
                final nextZoom = (_startZoom * details.scale)
                    .clamp(1.0, 4.0)
                    .toDouble();
                final nextPanX = frame.width * (1 - 1 / nextZoom) / 2;
                final nextPanY = frame.height * (1 - 1 / nextZoom) / 2;
                final delta = details.focalPoint - _startFocal;
                final nextOffset = Offset(
                  nextPanX <= 0
                      ? 0
                      : (_startOffset.dx - delta.dx / nextPanX)
                            .clamp(-1.0, 1.0)
                            .toDouble(),
                  nextPanY <= 0
                      ? 0
                      : (_startOffset.dy - delta.dy / nextPanY)
                            .clamp(-1.0, 1.0)
                            .toDouble(),
                );
                widget.onCropChanged?.call(nextZoom, nextOffset);
              },
              child: image,
            );
          }

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x66000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
                if (widget.onReplace != null || widget.onRemove != null)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Row(
                      children: [
                        if (widget.onReplace != null)
                          _OverlayButton(
                            icon: Icons.swap_horiz_rounded,
                            tooltip: 'Replace photo',
                            onTap: widget.onReplace!,
                          ),
                        if (widget.onReplace != null && widget.onRemove != null)
                          const SizedBox(width: AppSpacing.sm),
                        if (widget.onRemove != null)
                          _OverlayButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Remove photo',
                            onTap: widget.onRemove!,
                          ),
                      ],
                    ),
                  ),
                Positioned(
                  left: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                        child: Text(
                          widget.aspect.detail,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (canCrop) ...[
                        const SizedBox(width: 6),
                        _OverlayButton(
                          icon: Icons.restart_alt_rounded,
                          tooltip: 'Reset crop',
                          onTap: () {
                            Haptics.lightImpact();
                            widget.onCropChanged?.call(1.0, Offset.zero);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Accessibility description for the attached photo, sent as
/// `alt_text_custom` on publish.
class AltTextField extends StatefulWidget {
  const AltTextField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const int maxLength = 420;

  @override
  State<AltTextField> createState() => _AltTextFieldState();
}

class _AltTextFieldState extends State<AltTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AltTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLength: AltTextField.maxLength,
      minLines: 1,
      maxLines: 3,
      style: theme.textTheme.bodySmall,
      decoration: InputDecoration(
        labelText: 'Alt text',
        hintText: 'Describes the photo for screen readers',
        helperText: 'Optional · helps people using screen readers',
        counterStyle: theme.textTheme.labelSmall,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: () {
          Haptics.lightImpact();
          onTap();
        },
        icon: Icon(icon, size: 18, color: Colors.white),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Facebook feed rendering of the draft. Appears (and expands) only when an
/// image is attached, exactly like the composer's media preview.
class PostPreviewCard extends StatelessWidget {
  const PostPreviewCard({
    super.key,
    required this.pageName,
    required this.message,
    this.pagePictureUrl = '',
    this.imagePath,
    this.imageAspect = FacebookImageAspect.portrait,
    this.imageZoom = 1.0,
    this.imageOffset = Offset.zero,
    this.imageAltText = '',
    this.media = const [],
    this.onReplaceImage,
    this.onRemoveImage,
    this.animateImage = true,
    this.maxMessageLines = 10,
  });

  final String pageName;
  final String pagePictureUrl;
  final String message;
  final String? imagePath;
  final FacebookImageAspect imageAspect;
  final double imageZoom;
  final Offset imageOffset;
  final String imageAltText;
  final List<FacebookMediaItem> media;
  final VoidCallback? onReplaceImage;
  final VoidCallback? onRemoveImage;
  final bool animateImage;
  final int maxMessageLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = pageName.trim().isEmpty ? 'Your Page' : pageName;
    final hasMedia = media.isNotEmpty;
    final hasImage = hasMedia || (imagePath != null && imagePath!.isNotEmpty);
    final hasMessage = message.trim().isNotEmpty;
    final linkHost = _firstUrl(message);

    final Widget? image = hasMedia
        ? Semantics(
            label: media.isEmpty
                ? 'Attached photos'
                : (media.length == 1
                      ? _altLabel(media.first.altText)
                      : '${media.length} attached photos'),
            image: true,
            child: media.length > 1
                ? _PreviewCarousel(media: media)
                : Semantics(
                    label: _altLabel(media.first.altText),
                    image: true,
                    child: PreviewImage(
                      imagePath: media.first.path,
                      aspect: media.first.aspect,
                      zoom: media.first.zoom,
                      offset: media.first.offset,
                      interactive: false,
                    ),
                  ),
          )
        : hasImage
        ? Semantics(
            label: imageAltText.trim().isEmpty
                ? 'Attached photo'
                : imageAltText.trim(),
            image: true,
            child: PreviewImage(
              imagePath: imagePath!,
              aspect: imageAspect,
              zoom: imageZoom,
              offset: imageOffset,
              interactive: false,
              onReplace: onReplaceImage,
              onRemove: onRemoveImage,
            ),
          )
        : null;

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: AppSpacing.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                FacebookPageAvatar(
                  pageName: displayName,
                  pictureUrl: pagePictureUrl,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Just now',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.public_rounded,
                            size: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (hasMessage)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                0,
                AppSpacing.base,
                AppSpacing.md,
              ),
              child: Text(
                message,
                maxLines: maxMessageLines,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                0,
                AppSpacing.base,
                AppSpacing.md,
              ),
              child: Text(
                'Your post text will appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
          if (linkHost != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                0,
                AppSpacing.base,
                AppSpacing.md,
              ),
              child: _LinkLine(url: linkHost),
            ),
          if (image != null)
            animateImage
                ? AnimatedSize(
                    duration: AppMotion.transitionSpec,
                    curve: AppMotion.curveTransition,
                    alignment: Alignment.topCenter,
                    child: image,
                  )
                : image,
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Reaction(icon: Icons.thumb_up_alt_outlined, label: 'Like'),
                _Reaction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comment',
                ),
                _Reaction(icon: Icons.share_outlined, label: 'Share'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _altLabel(String altText) =>
      altText.trim().isEmpty ? 'Attached photo' : altText.trim();

  static String? _firstUrl(String text) {
    final match = RegExp(r'https?://[^\s]+').firstMatch(text);
    if (match == null) return null;
    final raw = match.group(0);
    if (raw == null || raw.isEmpty) return null;
    try {
      final host = Uri.parse(raw).host.replaceFirst(RegExp(r'^www\.'), '');
      return host.isEmpty ? null : host;
    } catch (_) {
      return null;
    }
  }
}

class _PreviewCarousel extends StatefulWidget {
  const _PreviewCarousel({required this.media});

  final List<FacebookMediaItem> media;

  @override
  State<_PreviewCarousel> createState() => _PreviewCarouselState();
}

class _PreviewCarouselState extends State<_PreviewCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final current = widget.media[_index.clamp(0, widget.media.length - 1)];
    return AspectRatio(
      aspectRatio: current.aspect.ratio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: widget.media.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final item = widget.media[index];
              return PreviewImage(
                imagePath: item.path,
                aspect: item.aspect,
                zoom: item.zoom,
                offset: item.offset,
                interactive: false,
              );
            },
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _Pill(label: '${_index + 1}/${widget.media.length}'),
          ),
          Positioned(
            bottom: AppSpacing.sm,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.media.length; i++)
                  AnimatedContainer(
                    duration: AppMotion.transitionSpec,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == _index ? 16 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _index ? Colors.white : Colors.white54,
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkLine extends StatelessWidget {
  const _LinkLine({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            'estimated',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Reaction extends StatelessWidget {
  const _Reaction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
