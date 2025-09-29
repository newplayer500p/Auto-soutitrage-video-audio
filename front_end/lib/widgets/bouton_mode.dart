// Exemple de widget "BoutonMode" responsive réutilisable.
import 'package:flutter/material.dart';

class BoutonMode extends StatelessWidget {
  final ThemeData theme;
  final bool isDarkMode;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onPressed;
  final bool compact;

  const BoutonMode({
    super.key,
    required this.theme,
    required this.isDarkMode,
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    final iconSize = isTablet ? 48.0 : 36.0;
    final titleSize = isTablet ? 18.0 : 16.0;
    final descSize = isTablet ? 14.0 : 13.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 14,
            vertical: isTablet ? 18 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue.shade700.withOpacity(0.18)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                ),
              ),
              SizedBox(width: isTablet ? 18 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: descSize,
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        height: 1.3,
                      ),
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: isTablet ? 18 : 14,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
