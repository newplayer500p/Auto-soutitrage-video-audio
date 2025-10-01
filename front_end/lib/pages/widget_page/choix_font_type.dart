import 'package:flutter/material.dart';

class FontChoice extends StatelessWidget {
  final String fontName;
  final ValueChanged<String> onChanged;
  const FontChoice({
    super.key,
    required this.fontName,
    required this.onChanged,
  });

  static const _fonts = [
    {'label': 'Roboto', 'value': 'Roboto'},
    {'label': 'Noto Sans', 'value': 'NotoSans'},
    {'label': 'Arial', 'value': 'Arial'},
    {'label': 'Times New Roman', 'value': 'TimesNewRoman'},
  ];

  void _openPicker(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [
                      Colors.grey.shade900,
                      Colors.grey.shade800,
                      Colors.grey.shade900,
                    ]
                  : [
                      Colors.blue.shade50,
                      Colors.grey.shade50,
                      Colors.blue.shade50,
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle indicator
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
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Choisir une police',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Font list
                  ..._fonts.map((f) {
                    final label = f['label']!;
                    final value = f['value']!;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          Icons.font_download,
                          color: isDarkMode
                              ? Colors.blue.shade200
                              : Colors.blue.shade700,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontFamily: value,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.grey.shade800,
                          ),
                        ),
                        subtitle: Text(
                          'Aa Bb Cc — aperçu rapide',
                          style: TextStyle(
                            fontFamily: value,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        trailing: fontName == value
                            ? Icon(
                                Icons.check_circle,
                                color: isDarkMode
                                    ? Colors.blue.shade200
                                    : Colors.blue.shade700,
                              )
                            : null,
                        onTap: () {
                          onChanged(value);
                          Navigator.pop(ctx);
                        },
                        tileColor: isDarkMode
                            ? Colors.grey.shade800.withOpacity(0.7)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
                  Icons.font_download,
                  size: 20,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Police de caractères',
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

          // Bouton pour ouvrir le picker
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
                    // Aperçu de la police
                    Expanded(
                      child: Text(
                        fontName,
                        style: TextStyle(
                          fontFamily: fontName,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Icône flèche
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
