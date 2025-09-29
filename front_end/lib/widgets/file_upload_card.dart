import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileUploadCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDarkMode;
  final String title;
  final PlatformFile? file;
  final IconData icon;
  final String buttonText;
  final VoidCallback onPressed;
  final bool required;
  final String? allowedExtensions;

  const FileUploadCard({
    required this.theme,
    required this.isDarkMode,
    required this.title,
    required this.file,
    required this.icon,
    required this.buttonText,
    required this.onPressed,
    this.required = false,
    this.allowedExtensions,
    super.key,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  String _getFileStatus() {
    if (file == null) return 'Aucun fichier sélectionné';
    return '${file!.name} (${_formatFileSize(file!.size)})';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? Colors.grey.shade800.withOpacity(0.7) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white
                              : Colors.blue.shade800,
                        ),
                      ),
                      if (required) ...[
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenu principal
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Partie gauche (statut) — prend tout l'espace restant
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade900.withOpacity(0.3)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            file != null ? Icons.check_circle : Icons.info,
                            size: 20,
                            color: file != null
                                ? Colors.green
                                : (isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file != null
                                      ? 'Fichier sélectionné'
                                      : 'En attente de fichier',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getFileStatus(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                if (allowedExtensions != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Extensions autorisées: $allowedExtensions',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDarkMode
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Partie droite (bouton) — s'étire à la même hauteur que la partie gauche
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [Colors.blue.shade700, Colors.blue.shade800]
                                : [Colors.blue.shade500, Colors.blue.shade600],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        // IMPORTANT : le SizedBox avec height: double.infinity permet au bouton
                        // d'occuper toute la hauteur fournie par l'IntrinsicHeight parent.
                        child: SizedBox(
                          height: double.infinity,
                          child: ElevatedButton(
                            onPressed: onPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.file_upload,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  buttonText,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
