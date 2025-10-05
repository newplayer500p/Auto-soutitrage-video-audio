// Combined updated widgets: BgColorPicker (confirm/cancel) + BackgroundChooser (uses dialog) + examples for FontColorChoice & FontOutlineChoice

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// -----------------------------
// BgColorPicker
// Dialog with Confirm / Cancel. Returns a Map {'color': Color, 'opacity': double} when confirmed (Navigator.pop(result)).
// -----------------------------
class BgColorPicker extends StatefulWidget {
  final Color initialColor;

  const BgColorPicker({super.key, required this.initialColor});

  @override
  State<BgColorPicker> createState() => _BgColorPickerState();
}

class _BgColorPickerState extends State<BgColorPicker> {
  late Color _tempColor;

  @override
  void initState() {
    super.initState();
    _tempColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      title: Row(
        children: [
          const Text(
            'Choisir la couleur',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Annuler',
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color picker
            ColorPicker(
              pickerColor: _tempColor,
              onColorChanged: (c) => setState(() => _tempColor = c),
              enableAlpha: false,
              showLabel: false,
              pickerAreaHeightPercent: 0.6,
            ),
            const SizedBox(height: 12),

            // Opacity slider with preview
            const SizedBox(height: 8),
            Text(
              'Appuie sur Confirmer pour enregistrer la couleur, ou Annuler pour revenir en arrière.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {'color': _tempColor});
          },
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
