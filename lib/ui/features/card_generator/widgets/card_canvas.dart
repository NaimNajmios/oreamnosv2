import 'package:flutter/material.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'package:google_fonts/google_fonts.dart';

class CardCanvas extends StatelessWidget {
  final CardData cardData;
  final CardTemplate template;
  final CardBackground background;
  final AppFont font;

  const CardCanvas({
    super.key,
    required this.cardData,
    required this.template,
    required this.background,
    this.font = AppFont.defaultFont,
  });

  TextStyle _getFontStyle(TextStyle baseStyle) {
    switch (font) {
      case AppFont.classicSerif:
        return GoogleFonts.lora(textStyle: baseStyle);
      case AppFont.typewriter:
        return GoogleFonts.spaceMono(textStyle: baseStyle);
      case AppFont.defaultFont:
      default:
        return GoogleFonts.inter(textStyle: baseStyle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5, // Instagram portrait ratio
      child: Container(
        decoration: _buildBackgroundDecoration(),
        padding: const EdgeInsets.all(32),
        child: _buildTemplateContent(),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    switch (background) {
      case CardBackground.solidDark:
      case CardBackground.minimalist:
      case CardBackground.magazineBold:
        return const BoxDecoration(color: Color(0xFF1E1E1E));
      case CardBackground.gradientBlue:
      case CardBackground.glassmorphism:
      case CardBackground.neonGlow:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case CardBackground.gradientOrange:
      case CardBackground.cutout:
      case CardBackground.offsetCard:
      case CardBackground.grunge:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9A3412), Color(0xFFF97316)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        );
    }
  }

  Widget _buildTemplateContent() {
    switch (template) {
      case CardTemplate.headlineQuote:
        return _buildQuoteTemplate();
      case CardTemplate.breakingNews:
        return _buildBreakingNewsTemplate();
      default:
        return _buildStandardTemplate();
    }
  }

  Widget _buildStandardTemplate() {
    final listFields = cardData.data.entries.where((e) => e.value is List).toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cardData.title.toUpperCase(),
                        style: _getFontStyle(
                          const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cardData.subtitle,
                        style: _getFontStyle(
                          const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (listFields.isNotEmpty) ...[
                        for (var item in (listFields.first.value as List).take(4))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Colors.white, fontSize: 18)),
                                Expanded(
                                  child: Text(
                                    item is Map ? (item['label'] != null ? "\${item['label']}: \${item['value']}" : item.toString()) : item.toString(),
                                    style: _getFontStyle(
                                      const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (listFields.isEmpty && cardData.data.containsKey('keyPoints')) ...[
                        for (var point in (cardData.data['keyPoints'] as List).take(4))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Colors.white, fontSize: 18)),
                                Expanded(
                                  child: Text(
                                    point.toString(),
                                    style: _getFontStyle(
                                      const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ]
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
    final quoteText = cardData.data['quote'] ?? cardData.data['keyQuote'] ?? cardData.subtitle;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.format_quote_rounded, size: 48, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        quoteText,
                        style: _getFontStyle(
                          const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(width: 40, height: 4, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        cardData.title,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
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

  Widget _buildBreakingNewsTemplate() {
    final label = cardData.data['label'] ?? 'BREAKING';
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: Colors.redAccent,
                        child: Text(
                          label.toString().toUpperCase(),
                          style: _getFontStyle(
                            const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cardData.title,
                        style: _getFontStyle(
                          const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cardData.subtitle,
                        style: _getFontStyle(
                          const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
          ),
        ),
        const Icon(Icons.sports_soccer, color: Colors.white54, size: 20),
      ],
    );
  }
}
