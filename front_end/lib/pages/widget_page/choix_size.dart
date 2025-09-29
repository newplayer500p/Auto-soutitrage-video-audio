// font_size_choice.dart
import 'package:flutter/material.dart';

class FontSizeChoice extends StatelessWidget {
  final double fontSize;
  final ValueChanged<double> onChanged;
  const FontSizeChoice({
    super.key,
    required this.fontSize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône
          Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 20,
                color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Taille de police:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                ),
              ),

              // Affichage de la valeur actuelle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue.shade800.withOpacity(0.2)
                      : Colors.blue.shade100.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(
                  'Taille actuelle : ${fontSize.toInt()}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? Colors.blue.shade200
                        : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isDarkMode
                  ? Colors.blue.shade200
                  : Colors.blue.shade700,
              inactiveTrackColor: isDarkMode
                  ? Colors.blue.shade200.withOpacity(0.25)
                  : Colors.blue.shade700.withOpacity(0.25),
              thumbColor: isDarkMode
                  ? Colors.blue.shade200
                  : Colors.blue.shade700,
              overlayColor: isDarkMode
                  ? Colors.blue.shade200.withOpacity(0.12)
                  : Colors.blue.shade700.withOpacity(0.12),
              trackHeight: 6,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 4,
              ),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              min: 12,
              max: 36,
              divisions: 24,
              label: fontSize.toInt().toString(),
              value: fontSize,
              onChanged: onChanged,
            ),
          ),

          // Échelle des valeurs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['12', '18', '24', '30', '36'].map((size) {
                return Text(
                  size,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontWeight: fontSize.toInt() == int.parse(size)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
