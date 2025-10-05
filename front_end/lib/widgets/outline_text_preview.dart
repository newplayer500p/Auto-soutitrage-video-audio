import 'package:flutter/material.dart';

/// Aperçu texte avec contour + remplissage
class OutlineTextPreview extends StatelessWidget {
  final String text;
  final Color outlineColor;
  final Color fillColor;
  final double fontSize;

  const OutlineTextPreview({
    super.key,
    this.text = 'Aperçu du contour',
    required this.outlineColor,
    required this.fillColor,
    this.fontSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    // background contrast léger
    final bg = fillColor.computeLuminance() > 0.5
        ? Colors.black12
        : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bg.withOpacity(0.06),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // stroke
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1
                  ..color = outlineColor,
              ),
            ),
            // fill
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: fillColor,
                shadows: [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.35),
                    offset: const Offset(1, 1),
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
