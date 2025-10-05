import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:front_end/pages/widget_page/choix_str_language.dart';
import 'package:front_end/widgets/file_upload_card.dart';

class UploadControls extends StatelessWidget {
  final List<String> languages;
  final bool isDarkMode;
  final PlatformFile? mediaFile;
  final String? mediaLang;
  final VoidCallback onPickMedia;
  final ValueChanged<String?> onMediaLangChanged;
  final bool isAudio;

  const UploadControls({
    required this.languages,
    required this.isDarkMode,
    required this.mediaFile,
    required this.mediaLang,
    required this.onPickMedia,
    required this.onMediaLangChanged,
    this.isAudio = false,
    super.key,
  });

  String _humanReadableSize(int? bytes) {
    if (bytes == null) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    double s = bytes.toDouble();
    int i = 0;
    while (s >= 1024 && i < units.length - 1) {
      s /= 1024;
      i++;
    }
    return '${s.toStringAsFixed(s < 10 ? 2 : 1)} ${units[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = isAudio
        ? "Sélection du fichier audio"
        : "Sélection de la vidéo";
    final subtitle = isAudio
        ? "Fichier audio (ex: mp3, wav)"
        : "Fichier vidéo (ex: mp4, mov)";
    final icon = isAudio ? Icons.audiotrack : Icons.videocam;
    final buttonText = isAudio
        ? "Sélectionner un audio"
        : "Sélectionner une vidéo";

    return LayoutBuilder(
      builder: (context, constraints) {
        // mobile-first breakpoints (ajuste à ton goût)
        final double maxWidth = constraints.maxWidth;
        final bool isCompact = maxWidth < 420;

        // compact sizing values
        final double containerPadding = isCompact ? 12 : 20;
        final double headerPadding = isCompact ? 8 : 12;
        final double iconSize = isCompact ? 18 : 20;
        final double titleFontSize = isCompact ? 18 : 24;
        final double sectionSpacing = isCompact ? 10 : 20;
        final double verticalDividerSpace = isCompact ? 6 : 8;

        return Container(
          padding: EdgeInsets.all(containerPadding),
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
              // Header
              Container(
                padding: EdgeInsets.all(headerPadding),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isDarkMode
                          ? Colors.blue.shade200
                          : const Color.fromARGB(255, 0, 62, 133),
                      size: iconSize,
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.start,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: titleFontSize,
                          color: isDarkMode
                              ? Colors.white
                              : const Color.fromARGB(255, 0, 62, 133),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing),
              Divider(height: 1),

              // Controls
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Language dropdown (compact -> denser)
                  LangueDropdown(
                    theme: theme,
                    isDarkMode: isDarkMode,
                    title: isAudio ? "Langue de l'audio" : "Langue de la vidéo",
                    selected: mediaLang,
                    onChanged: onMediaLangChanged,
                    languages: languages,
                    // If your LangueDropdown supports a compact flag, pass it here.
                  ),

                  SizedBox(height: verticalDividerSpace),
                  Divider(),
                  SizedBox(height: verticalDividerSpace),

                  // File upload card: pass compact flag if your FileUploadCard accepts it
                  FileUploadCard(
                    theme: theme,
                    isDarkMode: isDarkMode,
                    title: subtitle,
                    file: mediaFile,
                    icon: icon,
                    buttonText: buttonText,
                    onPressed: onPickMedia,
                    required: true,
                    // optional: if FileUploadCard supports a compact bool, uncomment:
                    // compact: isCompact,
                  ),

                  SizedBox(height: isCompact ? 6 : 8),

                  // Compact display of file name + size
                  if (mediaFile != null)
                    Padding(
                      padding: EdgeInsets.only(
                        top: isCompact ? 6.0 : 8.0,
                        left: 4.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              mediaFile!.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isCompact ? 12 : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            _humanReadableSize(mediaFile!.size),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontSize: isCompact ? 11 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
