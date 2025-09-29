import 'package:flutter/material.dart';

class LangueDropdown extends StatelessWidget {
  final ThemeData theme;
  final bool isDarkMode;
  final String title;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final List<String> languages;

  const LangueDropdown({
    required this.theme,
    required this.isDarkMode,
    required this.title,
    required this.selected,
    required this.onChanged,
    required this.languages,
    super.key,
  });

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'Anglais';
      case 'mg':
        return 'Malagasy';
      case 'es':
        return 'Espagnol';
      case 'de':
        return 'Allemand';
      case 'other':
        return 'Autre';
      default:
        return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? Colors.grey.shade800.withOpacity(0.7) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  size: 22,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dropdown stylisé
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
                value: selected,
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
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                  size: 28,
                ),
                dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                items: languages.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _getLanguageName(value),
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade200
                              : Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
