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
    instruction:
        'Improve the flow and clarity of the report without adding new facts.',
    icon: Icons.auto_fix_high_rounded,
  ),
  DefaultPill(
    id: 'default_shorter',
    label: 'Shorter',
    instruction:
        'Make the report shorter, 100-120 words, keeping a formal style.',
    icon: Icons.compress_rounded,
  ),
];
