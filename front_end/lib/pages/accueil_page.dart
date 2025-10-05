import 'package:flutter/material.dart';

class AccueilPage extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const AccueilPage({super.key, required this.onToggleTheme});

  void _allerVersUpload(BuildContext context, {required bool isAudio}) {
    Navigator.pushNamed(context, '/upload', arguments: {'isAudio': isAudio});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: _buildAppBar(theme, isDarkMode),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 800;
            final double horizontalPadding = _getHorizontalPadding(
              isDesktop,
              isTablet,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isTablet ? 32 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(theme, isTablet),
                  const SizedBox(height: 40),
                  _buildActionCards(context, isWide),
                  const SizedBox(height: 48),
                  _buildFooter(theme, isDarkMode),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDarkMode) {
    return AppBar(
      title: Text(
        "Sous-titrage Vidéo",
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onBackground,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.amber.withOpacity(0.15)
                  : Colors.blueGrey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: isDarkMode ? Colors.amber : Colors.blueGrey,
              size: 22,
            ),
          ),
          onPressed: onToggleTheme,
          tooltip: isDarkMode ? 'Mode clair' : 'Mode sombre',
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool isTablet) {
    return Column(
      children: [
        // Icon decoration avec effet de profondeur
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.primary.withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.subtitles_rounded,
            size: isTablet ? 90 : 70,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Sous-titrage Professionnel",
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: isTablet ? 28 : 24,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Transformez vos vidéos et fichiers audio avec des sous-titres précis et personnalisables. Support multilingue et options avancées de mise en forme.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context, bool isWide) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: _buildVideoCard(context)),
          const SizedBox(width: 20),
          Expanded(child: _buildAudioCard(context)),
        ],
      );
    }

    return Column(
      children: [
        _buildVideoCard(context),
        const SizedBox(height: 20),
        _buildAudioCard(context),
      ],
    );
  }

  Widget _buildVideoCard(BuildContext context) {
    return _ModernActionCard(
      icon: Icons.video_library_rounded,
      title: "Vidéo",
      subtitle: "Sous-titrez vos vidéos avec précision",
      features: const [
        "Format multiples",
        "Synchro automatique",
        "Style personnalisable",
      ],
      accentColor: Colors.blue,
      onPressed: () => _allerVersUpload(context, isAudio: false),
    );
  }

  Widget _buildAudioCard(BuildContext context) {
    return _ModernActionCard(
      icon: Icons.audio_file_rounded,
      title: "Audio",
      subtitle: "Transcription et sous-titrage audio",
      features: const [
        "Format multiples",
        "Synchro automatique",
        "Creation de video avec style personalisable ",
      ],
      accentColor: Colors.purple,
      onPressed: () => _allerVersUpload(context, isAudio: true),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDarkMode) {
    return Column(
      children: [
        Divider(color: theme.dividerColor.withOpacity(0.3), height: 40),
        Text(
          "Prêt à commencer ? Choisissez votre type de fichier ci-dessus",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 6),
            Text(
              "Besoin d'aide ? Consultez notre centre d'aide",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getHorizontalPadding(bool isDesktop, bool isTablet) {
    if (isDesktop) return 80;
    if (isTablet) return 40;
    return 24;
  }
}

class _ModernActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final Color accentColor;
  final VoidCallback onPressed;

  const _ModernActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDarkMode
            ? theme.colorScheme.surface.withOpacity(0.8)
            : theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? theme.colorScheme.outline.withOpacity(0.2)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: accentColor),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                // Features list
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          feature,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Commencer",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
