import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:front_end/pages/controls/show_download_option.dart';
import 'package:front_end/pages/controls/upload_controlle.dart';
import 'package:front_end/pages/widget_page/action_button.dart';
import 'package:front_end/pages/widget_page/choix_font.dart';
import 'package:front_end/pages/widget_page/choix_position.dart';
import 'package:front_end/pages/widget_page/choix_size.dart';
import 'package:front_end/pages/widget_page/header_card.dart';
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

  PlatformFile? _videoFile;

  final String _backendBase = 'http://127.0.0.1:8000';
  final List<String> _supportedLanguages = ['fr', 'en', 'mg', "es", "de"];

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateForm() {
    if (_videoFile == null) {
      _showError('Veuillez sélectionner une vidéo');
      return false;
    }

    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() => _isProcessing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Traitement en cours...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final api = ApiService();
      final response = await api.uploadVideo(
        baseUrl: _backendBase,
        videoFile: _videoFile!,
        language: _videoLanguage,
        position: _position,
        fontName: _fontName,
        fontSize: _fontSize.toInt(),
      );

      Navigator.of(context).pop(); // Close progress dialog

      if (response['ok'] == true) {
        _showSuccess("Traitement effectuer");

        // Option: Navigate to result page or show preview
        showDownloadOptions(context, {
          "video": response["video"] ?? "",
          "vocals": response["vocals"] ?? "",
          "srt": response["srt"] ?? "",
          "subtitled": response["subtitled_video"] ?? "",
        });
      } else {
        final error = response['error'] ?? 'Erreur inconnue';
        _showError('Erreur lors du traitement: $error');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showError('Erreur de connexion: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres de sous-titrage',
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
              HeaderCard(isDarkMode: isDarkMode),
              const SizedBox(height: 24),

              // Upload Controls Section
              UploadControls(
                languages: _supportedLanguages,
                isDarkMode: isDarkMode,
                video: _videoFile,
                videoLang: _videoLanguage,
                onPickVideo: _pickVideo,
                onVideoLangChanged: (lang) =>
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

                    Divider(),

                    // Position and Language Row
                    PositionChoice(
                      position: _position,
                      onChanged: (v) =>
                          setState(() => _position = v ?? 'bottom-center'),
                    ),
                    const SizedBox(height: 16),
                    Divider(),

                    // Font Settings
                    FontChoice(
                      fontName: _fontName,
                      onChanged: (v) => setState(() => _fontName = v),
                    ),

                    const SizedBox(height: 12),
                    Divider(),

                    FontSizeChoice(
                      fontSize: _fontSize,
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
