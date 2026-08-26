import 'package:flutter/material.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Threads-styled switch wrapping Material Switch with haptics.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged == null
          ? null
          : (v) {
              Haptics.selectionClick();
              onChanged!.call(v);
            },
    );
  }
}
