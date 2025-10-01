import 'package:flutter/material.dart';

class HeaderCard extends StatelessWidget {
  final bool isDarkMode;
  const HeaderCard({required this.isDarkMode, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.blue.shade800.withOpacity(0.2)
            : Colors.blue.shade100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description,
            size: 32,
            color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Sélectionnez la langue puis une vidéo pour un sous-titrage automatique",
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
