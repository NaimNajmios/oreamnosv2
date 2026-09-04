import 'package:flutter/material.dart';

/// Predefined standard AI refinement action.
class DefaultPill {
  final String id;
  final String label;
  final String instruction;
  final IconData icon;

  const DefaultPill({
    required this.id,
    required this.label,
    required this.instruction,
    required this.icon,
  });
}

/// Standard predefined refinement actions available in the generation view.
const List<DefaultPill> kDefaultRefinementPills = [
  DefaultPill(
    id: 'default_rephrase',
    label: 'Rephrase',
    instruction: 'Rephrase the report to be more formal and concise while keeping all facts and a neutral tone.',
    icon: Icons.refresh_rounded,
  ),
  DefaultPill(
    id: 'default_check_flow',
    label: 'Check Flow',
    instruction: 'Improve the reading flow of this content by adjusting sentence rhythm, transition words, and paragraph structure. Ensure it reads smoothly and naturally, but do not change the core meaning or key details.',
    icon: Icons.auto_fix_high_rounded,
  ),
  DefaultPill(
    id: 'default_shorter',
    label: 'Shorter',
    instruction: 'Act as a concise editor. Condense the following text significantly for brevity, but retain all key facts, data, and nuanced details. Do not simplify or remove substantive information.',
    icon: Icons.compress_rounded,
  ),
  DefaultPill(
    id: 'default_bullet_points',
    label: 'Bullet Points',
    instruction: 'Transform the provided content into clear, structured bullet points while preserving all key details and logical flow.',
    icon: Icons.format_list_bulleted_rounded,
  ),
  DefaultPill(
    id: 'default_sports_stats',
    label: 'Stats & Timeline',
    instruction: 'Format the following sports stats and timeline into well-organized bullet points. Keep all numbers and chronological details intact. Use sub-bullets if needed for clarity.',
    icon: Icons.timeline_rounded,
  ),
  DefaultPill(
    id: 'default_sports_post',
    label: 'Sports Post',
    instruction: 'Condense this long article into a short, punchy sports post. Use tight sentences, key stats, and match highlights. Match the energetic, fast-paced style typical of football or sports pages.',
    icon: Icons.sports_soccer_rounded,
  ),
  DefaultPill(
    id: 'default_split_paragraphs',
    label: 'Split Paragraphs',
    instruction: 'Split the content into well-spaced paragraphs for clarity and readability. Keep all existing content identical without removing details or changing the core facts.',
    icon: Icons.density_medium_rounded,
  ),
  DefaultPill(
    id: 'default_restructure',
    label: 'Restructure',
    instruction: 'Analyze the provided content and restructure it for optimal clarity and readability. Transform paragraphs into bullet points or subheaded sections where it would improve information flow, or use paragraphs where narrative flow is better. Preserve all key information and logical connections.',
    icon: Icons.schema_rounded,
  ),
  DefaultPill(
    id: 'default_grammar_check',
    label: 'Grammar Check',
    instruction: 'Review and correct all grammar, punctuation, and syntax errors in this text. Ensure proper sentence structure and subject-verb agreement while preserving the original meaning and style.',
    icon: Icons.spellcheck_rounded,
  ),
  DefaultPill(
    id: 'default_fix_translation',
    label: 'Fix Translation',
    instruction: 'Review this content and rewrite any awkward or stiff phrasing to sound more natural and fluent in English. Focus on improving word choice, flow, and readability, but do not change the core meaning or remove any details.',
    icon: Icons.translate_rounded,
  ),
];
