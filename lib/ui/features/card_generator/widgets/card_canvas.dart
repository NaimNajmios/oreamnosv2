import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

/// Sparse companion canvas — headline + hook + optional microStat badge
/// over an optional real image with dark scrim. No source/hashtags.
class CardCanvas extends StatelessWidget {
  final CardData cardData;
  final CardTemplate template;
  final AppFont font;
  final File? backgroundImage;
  final double scrimOpacity;
  final bool useVignette;

  const CardCanvas({
    super.key,
    required this.cardData,
    required this.template,
    this.font = AppFont.defaultFont,
    this.backgroundImage,
    this.scrimOpacity = 0.55,
    this.useVignette = false,
  });

  TextStyle _font(TextStyle base) {
    switch (font) {
      case AppFont.classicSerif:
        return GoogleFonts.lora(textStyle: base);
      case AppFont.typewriter:
        return GoogleFonts.spaceMono(textStyle: base);
      case AppFont.defaultFont:
        return GoogleFonts.inter(textStyle: base);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildBackgroundDecoration(),
      child: Stack(
        children: [
          // Scrim layer when image present
          if (backgroundImage != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: scrimOpacity),
                      Colors.black.withValues(alpha: (scrimOpacity * 0.62).clamp(0.2, 0.75)),
                    ],
                  ),
                ),
              ),
            ),
          // Vignette
          if (useVignette)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.15,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.32)],
                    stops: const [0.65, 1.0],
                  ),
                ),
              ),
            ),
          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: _buildTemplateContent(),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    if (backgroundImage != null) {
      return BoxDecoration(
        color: const Color(0xFF111111),
        image: DecorationImage(
          image: FileImage(backgroundImage!),
          fit: BoxFit.cover,
        ),
      );
    }
    // No image — subtle editorial dark
    return const BoxDecoration(color: Color(0xFF141416));
  }

  Widget _buildTemplateContent() {
    switch (template) {
      case CardTemplate.headlineQuote:
        return _buildQuoteTemplate();
      case CardTemplate.breakingNews:
        return _buildBreakingTemplate();
      case CardTemplate.statBadge:
        return _buildStatBadgeTemplate();
      case CardTemplate.standard:
        return _buildStandardTemplate();
    }
  }

  Widget _buildStandardTemplate() {
    return LayoutBuilder(
      builder: (context, c) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (cardData.hasMicroStat)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Text(
                            cardData.microStat!.toUpperCase(),
                            style: _font(
                              const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        cardData.headline.toUpperCase(),
                        style: _font(
                          const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
                            letterSpacing: -0.9,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Container(width: 36, height: 3, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(height: 14),
                      Text(
                        cardData.subtext,
                        style: _font(
                          const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.45,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBranding(),
          ],
        );
      },
    );
  }

  Widget _buildQuoteTemplate() {
    return LayoutBuilder(
      builder: (context, c) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.format_quote_rounded, size: 42, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(height: 12),
                      Text(
                        cardData.subtext.isNotEmpty ? cardData.subtext : cardData.headline,
                        style: _font(
                          const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),
                      Container(width: 32, height: 3, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        cardData.headline.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (cardData.hasMicroStat) ...[
                        const SizedBox(height: 8),
                        Text(
                          cardData.microStat!,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBranding(),
          ],
        );
      },
    );
  }

  Widget _buildBreakingTemplate() {
    final label = cardData.hasMicroStat ? cardData.microStat! : 'TERKINI';
    return LayoutBuilder(
      builder: (context, c) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        color: const Color(0xFFE11D48),
                        child: Text(
                          label.toUpperCase(),
                          style: _font(
                            const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cardData.headline.toUpperCase(),
                        style: _font(
                          const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
                            letterSpacing: -1.0,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cardData.subtext,
                        style: _font(
                          const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBranding(),
          ],
        );
      },
    );
  }

  Widget _buildStatBadgeTemplate() {
    return LayoutBuilder(
      builder: (context, c) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cardData.headline.toUpperCase(),
                        style: _font(
                          const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
                            letterSpacing: -0.8,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      if (cardData.hasMicroStat)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE11D48),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  cardData.microStat!,
                                  style: _font(
                                    const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111111),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      Text(
                        cardData.subtext,
                        style: _font(
                          const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.45,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBranding(),
          ],
        );
      },
    );
  }

  Widget _buildBranding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Oreamnos',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.72),
            letterSpacing: 0.6,
          ),
        ),
        Icon(Icons.sports_soccer, color: Colors.white.withValues(alpha: 0.62), size: 16),
      ],
    );
  }
}
