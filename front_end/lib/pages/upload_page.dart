import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:front_end/pages/controls/upload_controlle.dart';
import 'package:front_end/pages/controls/action_button.dart';
import 'package:front_end/pages/widget_page/choix_fond_video.dart';
import 'package:front_end/pages/widget_page/choix_font_color.dart';
import 'package:front_end/pages/widget_page/choix_font_outlined_color.dart';
import 'package:front_end/pages/widget_page/choix_font_type.dart';
import 'package:front_end/pages/widget_page/choix_str_position.dart';
import 'package:front_end/pages/widget_page/choix_font_size.dart';
import 'package:front_end/pages/card/header_card.dart';
import 'package:front_end/pages/widget_page/fond_subtitle/wav_signale_option.dart';
import 'package:front_end/widgets/processing_page.dart';
import '../services/api_service.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  // Form state
  String _videoLanguage = 'fr';
  String _position = 'bottom-center';
  String _fontName = 'Arial';
  double _fontSize = 24;
  bool _isProcessing = false;
  String _fontColorHex = '#FFFFFF';
  String _fontOutlineHex = '#000000';

  PlatformFile? _videoFile; // holds either audio or video depending on mode
  PlatformFile? _fondFile;
  String? _fondHex = '#000000';
  bool _showWavForm = false;
  bool _subtitleFromAudio = false;

  final String _backendBase = 'http://127.0.0.1:8000';
  final List<String> _supportedLanguages = ['fr', 'en', "es", "de"];

  // --- Video picker (existing behavior)
  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: kIsWeb,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _videoFile = result.files.first);
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de la vidéo: $e');
    }
  }

  // --- Audio picker (nouveau)
  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: kIsWeb,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(
          () => _videoFile = result.files.first,
        ); // réutilise le champ _videoFile
      }
    } catch (e) {
      _showError('Erreur lors de la sélection du fichier audio: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateForm() {
    if (_videoFile == null) {
      _showError(
        _subtitleFromAudio
            ? 'Veuillez sélectionner un fichier audio'
            : 'Veuillez sélectionner une vidéo',
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() => _isProcessing = true);

    try {
      final api = ApiService(_backendBase);
      final response = await api.uploadVideo(
        videoFile: _videoFile!,
        language: _videoLanguage,
        position: _position,
        fontName: _fontName,
        fontSize: _fontSize.toInt(),
        fontColor: _fontColorHex,
        outlineColor: _fontOutlineHex,
        fond: (_fondFile == null) ? (_fondHex ?? '#000000') : null,
        fondFile: _fondFile,
        showWavForm: _showWavForm,
      );

      if (response.containsKey('job_id')) {
        final String jobId = response['job_id'] as String;
        final List<Map<String, dynamic>> tasks =
            (response['tasks'] as List<dynamic>? ?? [])
                .map((t) => Map<String, dynamic>.from(t as Map))
                .toList();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProcessingPage(
              baseUrl: _backendBase,
              jobId: jobId,
              initialTasks: tasks,
            ),
          ),
        );
        return;
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showError('Erreur de connexion: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['isAudio'] == true) {
      _subtitleFromAudio = true;
    }
    super.didChangeDependencies();
  }

  Widget _buildBackgroundSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.image_search,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : const Color.fromARGB(255, 0, 62, 133),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Parametre du fond',
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
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 20),

          // Background Chooser
          BackgroundChooser(
            initialColorHex: _fondHex ?? '#000000',
            onChanged: (map) {
              setState(() {
                _fondHex = map['fond'] as String?;
                _fondFile = map['fond_file'] as PlatformFile?;
              });
            },
          ),

          const SizedBox(height: 20),
          const Divider(),

          const SizedBox(height: 16),
          WavSignaleOption(
            onChanged: (v) => setState(() => _showWavForm = v),
            waveForm: _showWavForm,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final title = _subtitleFromAudio
        ? 'Paramètres de sous-titrage (Audio)'
        : 'Paramètres de sous-titrage (Vidéo)';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Card
              HeaderCard(isDarkMode: isDarkMode, isAudio: _subtitleFromAudio),
              const SizedBox(height: 24),

              // Upload Controls Section
              UploadControls(
                languages: _supportedLanguages,
                isDarkMode: isDarkMode,
                mediaFile: _videoFile,
                mediaLang: _videoLanguage,
                isAudio: _subtitleFromAudio,
                onPickMedia: _subtitleFromAudio ? _pickAudio : _pickVideo,
                onMediaLangChanged: (lang) =>
                    setState(() => _videoLanguage = lang ?? 'fr'),
              ),

              const SizedBox(height: 24),

              // Style Settings Section
              Container(
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
                  children: [
                    // Section Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.style,
                            color: isDarkMode
                                ? Colors.blue.shade200
                                : const Color.fromARGB(255, 0, 62, 133),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Style des sous-titres',
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
                    const Divider(),

                    // Position and Language Row
                    PositionChoice(
                      position: _position,
                      onChanged: (v) =>
                          setState(() => _position = v ?? 'bottom-center'),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    // Font Settings
                    FontChoice(
                      fontName: _fontName,
                      onChanged: (v) => setState(() => _fontName = v),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),

                    // Choix couleur du texte
                    FontColorChoice(
                      colorHex: _fontColorHex,
                      onChanged: (hex) => setState(() => _fontColorHex = hex),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),

                    // Choix couleur du contour
                    FontOutlineChoice(
                      outlineHex: _fontOutlineHex,
                      onChanged: (hex) => setState(() => _fontOutlineHex = hex),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),

                    FontSizeChoice(
                      fontSize: _fontSize,
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sections conditionnelles pour audio
              if (_subtitleFromAudio) ...[_buildBackgroundSection()],

              const SizedBox(height: 16),

              // Action Button
              ActionButton(
                isProcessing: _isProcessing,
                isDarkMode: isDarkMode,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
