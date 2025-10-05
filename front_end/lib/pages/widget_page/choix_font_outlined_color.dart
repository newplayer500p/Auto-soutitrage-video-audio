import 'package:flutter/material.dart';
import 'package:front_end/pages/card/bg_color_picker.dart';
import 'package:front_end/pages/helper/color_hex.dart';

class FontOutlineChoice extends StatelessWidget {
  final String outlineHex;
  final ValueChanged<String> onChanged;

  const FontOutlineChoice({
    super.key,
    required this.outlineHex,
    required this.onChanged,
  });

  void _openPicker(BuildContext ctx) async {
    Color initial;
    try {
      initial = hexToColor(outlineHex);
    } catch (_) {
      initial = Colors.black;
    }

    final result = await showDialog(
      context: ctx,
      builder: (_) => BgColorPicker(initialColor: initial.withOpacity(1.0)),
    );

    if (result == null) return;
    if (result is Map && result.containsKey('color')) {
      final Color picked = (result['color'] as Color);
      final String hexOut = colorToHex(picked);
      onChanged(hexOut);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Contour appliqué : $hexOut'),
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
      current = hexToColor(outlineHex);
    } catch (_) {
      current = Colors.black;
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
                  Icons.format_paint,
                  size: 20,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Couleur du contour',
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
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: current,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black26, width: 2),
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
