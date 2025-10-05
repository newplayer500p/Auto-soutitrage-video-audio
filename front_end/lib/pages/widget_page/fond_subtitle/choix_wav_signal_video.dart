// waveform_option.dart
import 'package:flutter/material.dart';

class WaveformOption extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDarkMode;
  final String label;

  const WaveformOption({
    super.key,
    required this.value,
    this.onChanged,
    this.label = "Afficher la forme d'onde",
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade900.withOpacity(0.5)
            : Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.blue.shade800.withOpacity(0.3)
              : Colors.blue.shade200,
          width: 1.2,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          label,
          style: TextStyle(
            fontFamily: "Arial",
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        value: value,
        activeThumbColor: const Color.fromARGB(255, 1, 94, 255),
        onChanged: onChanged,
      ),
    );
  }
}
