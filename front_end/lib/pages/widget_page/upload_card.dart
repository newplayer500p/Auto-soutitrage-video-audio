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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.7)
            : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue.shade800.withOpacity(0.2)
                      : Colors.blue.shade100.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blue.shade800.withOpacity(0.3)
                            : Colors.blue.shade100.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isDarkMode
                            ? Colors.blue.shade200
                            : Colors.blue.shade700,
                      ),
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
                    if (file != null) ...[
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contenu principal
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statut du fichier
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade900.withOpacity(0.3)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                file != null
                                    ? Icons.file_present
                                    : Icons.file_open,
                                size: 18,
                                color: file != null
                                    ? (isDarkMode
                                          ? Colors.green.shade300
                                          : Colors.green.shade600)
                                    : (isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade500),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getFileStatus(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDarkMode
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                    fontWeight: file != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (allowedExtensions != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Extensions autorisées: $allowedExtensions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDarkMode
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bouton d'action
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: file != null
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDarkMode
                                  ? [Colors.blue.shade700, Colors.blue.shade800]
                                  : [
                                      Colors.blue.shade500,
                                      Colors.blue.shade600,
                                    ],
                            ),
                    ),
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: file != null
                            ? (isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300)
                            : Colors.transparent,
                        foregroundColor: file != null
                            ? (isDarkMode
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        elevation: file != null ? 0 : 2,
                      ),
                      child: Text(
                        file != null ? 'Modifier' : buttonText,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: file != null
                              ? (isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
