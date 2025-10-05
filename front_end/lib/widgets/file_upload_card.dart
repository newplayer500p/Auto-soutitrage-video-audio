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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? Colors.grey.shade800.withOpacity(0.7) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(), // icône + titre

            const SizedBox(height: 16),

            isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statusBox(),
                      const SizedBox(height: 12),
                      _uploadButton(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _statusBox()),
                      const SizedBox(width: 16),
                      // bouton flexible pour éviter overflow
                      _uploadButton(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // header simplifié
  Widget _header() {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.blue.shade800,
                  ),
                  overflow: TextOverflow.ellipsis, // <-- ajoute sécurité
                ),
              ),
              if (required)
                Text(
                  '*',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // bouton upload
  Widget _uploadButton() {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.file_upload, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              buttonText,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis, // <-- empêche overflow
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
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
                : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
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
                  maxLines: 1,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getFileStatus(),
                  maxLines: 1,
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
                    maxLines: 1,
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
    );
  }
}
