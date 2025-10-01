import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final String resultLabel;
  final bool isDarkMode;
  final VoidCallback onDownload;
  const ResultCard({
    required this.resultLabel,
    required this.isDarkMode,
    required this.onDownload,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.green.shade800.withOpacity(0.3)
            : Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.green.shade700 : Colors.green.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 48, color: Colors.green),
          SizedBox(height: 16),
          Text(
            "Sous-titrage terminé avec succès! 🎉",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.green.shade200 : Colors.green.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.download, size: 20),
            label: Text("Télécharger la vidéo"),
            onPressed: onDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? Colors.green.shade700
                  : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
