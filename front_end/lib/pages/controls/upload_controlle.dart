import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:front_end/pages/widget_page/choix_str_language.dart';
import 'package:front_end/widgets/file_upload_card.dart';

class UploadControls extends StatelessWidget {
  final List<String> languages;
  final bool isDarkMode;
  final PlatformFile? video; // Bien PlatformFile?
  final String? videoLang;
  final VoidCallback onPickVideo;
  final ValueChanged<String?> onVideoLangChanged;

  const UploadControls({
    required this.languages,
    required this.isDarkMode,
    required this.video,
    required this.videoLang,
    required this.onPickVideo,
    required this.onVideoLangChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.7)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.all(12),

            child: Row(
              children: [
                Icon(
                  Icons.video_library,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : const Color.fromARGB(255, 0, 62, 133),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Selection du video",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: isDarkMode
                        ? Colors.white
                        : const Color.fromARGB(255, 0, 62, 133),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(),

          // Contrôles de langue et upload
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LangueDropdown(
                theme: theme,
                isDarkMode: isDarkMode,
                title: "Langue de la vidéo",
                selected: videoLang,
                onChanged: onVideoLangChanged,
                languages: languages,
              ),

              const SizedBox(height: 8),
              Divider(),
              const SizedBox(height: 8),

              FileUploadCard(
                theme: theme,
                isDarkMode: isDarkMode,
                title: "Selection de la vidéo",
                file: video,
                icon: Icons.videocam,
                buttonText: "Sélectionner une vidéo",
                onPressed: onPickVideo,
                required: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
