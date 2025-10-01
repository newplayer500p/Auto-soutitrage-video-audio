import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_end/pages/helper/color_hex.dart';

class FontOutlineChoice extends StatelessWidget {
  final String outlineHex;
  final ValueChanged<String> onChanged;

  const FontOutlineChoice({
    super.key,
    required this.outlineHex,
    required this.onChanged,
  });

  void _openPicker(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final isDarkMode = theme.brightness == Brightness.dark;
    Color selected = Colors.transparent;
    try {
      selected = hexToColor(outlineHex);
    } catch (_) {
      selected = Colors.black;
    }

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDarkMode
                        ? [Colors.grey.shade900, Colors.grey.shade800]
                        : [Colors.blue.shade50, Colors.grey.shade50],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Choisir la couleur du contour',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Preview amélioré
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color.fromARGB(255, 34, 34, 34)
                                : const Color.fromARGB(255, 219, 219, 219),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              // Texte avec contour amélioré
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // outline (stroke) - plus épais pour mieux voir
                                    Text(
                                      'Aperçu du contours',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 4
                                          ..color = selected,
                                      ),
                                    ),
                                    // fill - avec fond pour mieux contraster
                                    Text(
                                      'Aperçu du contours',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2,
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Code couleur
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selected.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  colorToHex(selected),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Palette de couleurs avec titre
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Couleurs fréquentes',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Wrap(
                              runSpacing: 8,
                              spacing: 8,
                              children: commonHexColors.map((hex) {
                                final col = hexToColor(hex);
                                final isSelected =
                                    colorToHex(col) == colorToHex(selected);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => selected = col);
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: col,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        // Section saisie manuelle améliorée
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black26 : Colors.white54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Saisie manuelle',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Indicateur visuel de la couleur sélectionnée
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: selected,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? const Color(0x4D313131)
                                            : const Color(0x42CFCFCF),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: TextEditingController(
                                        text: colorToHex(selected),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Code hexadécimal',
                                        hintText: '#FF0000',
                                        border: const OutlineInputBorder(),
                                        isDense: true,

                                        filled: true,
                                        fillColor: isDarkMode
                                            ? Colors.grey.shade800
                                            : Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                      onChanged: (value) {
                                        final raw = value.trim();
                                        if (raw.isEmpty) return;

                                        // Support des formats avec et sans #
                                        String hexValue = raw;
                                        if (!hexValue.startsWith('#')) {
                                          hexValue = '#$hexValue';
                                        }

                                        // Validation basique
                                        if (hexValue.length == 7 ||
                                            hexValue.length == 9) {
                                          try {
                                            final color = hexToColor(hexValue);
                                            setState(() => selected = color);
                                          } catch (_) {
                                            // Ignorer les couleurs invalides
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final hexOut = colorToHex(selected);
                                      onChanged(hexOut);

                                      // Feedback visuel avant fermeture
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Couleur appliquée: $hexOut',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          duration: const Duration(
                                            milliseconds: 800,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );

                                      Future.delayed(
                                        const Duration(milliseconds: 800),
                                        () {
                                          Navigator.pop(ctx);
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text(
                                      'Appliquer',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode
                                          ? Colors.blue.shade600
                                          : Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Aide utilisateur
                              Text(
                                'Format: #RRGGBB ou #AARRGGBB (avec transparence)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
