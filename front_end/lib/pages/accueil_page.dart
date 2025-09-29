import 'package:flutter/material.dart';
import 'package:front_end/widgets/bouton_mode.dart';

// Fichier: accueil_page_responsive.dart
// Version mobile-first et responsive de la page d'accueil.
// Contient aussi un exemple simple de `BoutonMode` (widget réutilisable).

class AccueilPage extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const AccueilPage({super.key, required this.onToggleTheme});

  void _allerVersUpload(BuildContext context) {
    Navigator.pushNamed(context, '/upload');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Breakpoints simples (mobile-first)
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1000;

    // Padding adaptative : mobile-first (plus petit sur mobile)
    final horizontalPadding = isDesktop
        ? 64.0
        : isTablet
        ? 32.0
        : 20.0;

    final maxContentWidth =
        900.0; // pour garder une lecture confortable sur large écran

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sous-titrage Vidéo",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              // taille et couleur adaptatives
              size: isTablet ? 26 : 22,
              color: isDarkMode ? Colors.amber : Colors.blueGrey,
            ),
            onPressed: onToggleTheme,
            tooltip: isDarkMode ? 'Mode clair' : 'Mode sombre',
          ),
        ],
        elevation: 4,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isTablet ? 32 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête avec icône — mis en avant sur mobile
                  Container(
                    margin: EdgeInsets.only(bottom: isTablet ? 28 : 20),
                    padding: EdgeInsets.all(isTablet ? 20 : 14),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.blue.shade800.withOpacity(0.12)
                          : Colors.blue.shade100.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.subtitles,
                          size: isTablet ? 72 : 48,
                          color: isDarkMode
                              ? Colors.blue.shade200
                              : Colors.blue.shade700,
                        ),
                        SizedBox(height: isTablet ? 20 : 12),
                        Text(
                          "Bienvenue dans notre application de sous-titrage vidéo",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: isTablet ? 22 : 18,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Description
                  Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 14),
                    margin: EdgeInsets.only(bottom: isTablet ? 32 : 20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800.withOpacity(0.7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "Cette application vous permet d'ajouter des sous-titres personnalisables à vos vidéos."
                      " Fournissez uniquement une vidéo (support: Français / Anglais / Allemand / Espagnol).\n\n"
                      "Options: choix de langue, position des sous-titres, police, taille et plus.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        fontSize: isTablet ? 16 : 14,
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),

                  // Boutons d'action — responsive: sur grand écran on aligne côte à côte
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 8,
                          vertical: isTablet ? 20 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade800.withOpacity(0.7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: BoutonMode(
                          theme: theme,
                          isDarkMode: isDarkMode,
                          icon: Icons.video_library,
                          label: "Commencer",
                          description:
                              "Sous-titrage automatique pour vidéos (FR / EN / DE / ES)",
                          onPressed: () => _allerVersUpload(context),
                          compact: false,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Footer simple
                  Text(
                    'Besoin d\'aide ? Paramètres et FAQ dans le menu.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
