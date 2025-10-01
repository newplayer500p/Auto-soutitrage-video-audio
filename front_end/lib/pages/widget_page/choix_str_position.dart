// position_choice.dart
import 'package:flutter/material.dart';

class PositionChoice extends StatelessWidget {
  final String position; // one of the 9 values
  final ValueChanged<String?> onChanged;
  const PositionChoice({
    super.key,
    required this.position,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final choices = [
      {'label': 'Haut - Gauche', 'value': 'top-left'},
      {'label': 'Haut - Centre', 'value': 'top-center'},
      {'label': 'Haut - Droite', 'value': 'top-right'},
      {'label': 'Milieu - Gauche', 'value': 'center-left'},
      {'label': 'Milieu - Centre', 'value': 'center'},
      {'label': 'Milieu - Droite', 'value': 'center-right'},
      {'label': 'Bas - Gauche', 'value': 'bottom-left'},
      {'label': 'Bas - Centre', 'value': 'bottom-center'},
      {'label': 'Bas - Droite', 'value': 'bottom-right'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label avec icône
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.format_align_center,
                  size: 20,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Position des sous-titres',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? Colors.blue.shade200
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Dropdown dans un conteneur stylisé
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey.shade900.withOpacity(0.5)
                  : Colors.blue.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.blue.shade800.withOpacity(0.3)
                    : Colors.blue.shade200,
                width: 1.5,
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: position,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                size: 28,
              ),
              dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              items: choices
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['value'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          c['label']!,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade200
                                : Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
