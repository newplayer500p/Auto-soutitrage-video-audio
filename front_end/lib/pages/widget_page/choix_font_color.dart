import 'package:flutter/material.dart';
import 'package:front_end/pages/card/bg_color_picker.dart';
import 'package:front_end/pages/helper/color_hex.dart';

class FontColorChoice extends StatelessWidget {
  final String colorHex;
  final ValueChanged<String> onChanged;

  const FontColorChoice({
    super.key,
    required this.colorHex,
    required this.onChanged,
  });

  void _openPicker(BuildContext ctx) async {
    // couleur initiale (catch si hex invalide)
    Color initial;
    try {
      initial = hexToColor(colorHex);
    } catch (_) {
      initial = Colors.white;
    }
    // récupération de l'opacité depuis le channel alpha de la couleur

    final result = await showDialog(
      context: ctx,
      builder: (_) => BgColorPicker(
        initialColor: initial.withOpacity(1.0), // passer couleur sans alpha
      ),
    );

    if (result == null) return; // annulation
    if (result is Map && result.containsKey('color')) {
      final Color pickedColor = (result['color'] as Color);
      final String hexOut = colorToHex(pickedColor);
      onChanged(hexOut);
      // petit feedback
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Couleur appliquée : $hexOut'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color current;
    try {
      current = hexToColor(colorHex);
    } catch (_) {
      current = Colors.white;
    }
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.format_color_text,
                  size: 20,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Couleur du texte',
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

          // Button-like row
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
                width: 1.2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openPicker(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // color swatch + hex
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: current,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        colorToHex(current),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: isDarkMode
                          ? Colors.blue.shade200
                          : Colors.blue.shade700,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
