import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../card/bg_color_picker.dart';

class BackgroundChooser extends StatefulWidget {
  final String initialColorHex;
  final ValueChanged<Map<String, dynamic>>? onChanged;

  const BackgroundChooser({
    super.key,
    this.initialColorHex = '#000000',
    this.onChanged,
  });

  @override
  State<BackgroundChooser> createState() => _BackgroundChooserState();
}

enum _BgMode { color, image }

class _BackgroundChooserState extends State<BackgroundChooser> {
  _BgMode _mode = _BgMode.color;
  Color _pickedColor = const Color(0xFF000000);
  PlatformFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _parseInitialColor();
    // Notify parent after first frame so the parent knows the initial value
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChange());
  }

  void _parseInitialColor() {
    final hex = widget.initialColorHex;
    try {
      if (hex.startsWith('#')) {
        final v = int.parse(hex.substring(1), radix: 16);
        if (hex.length == 7) {
          _pickedColor = Color(0xFF000000 | v);
        } else if (hex.length == 9) {
          _pickedColor = Color(v);
        }
      }
    } catch (_) {}
  }

  String _colorToHex(Color c) {
    return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        _pickedImage = res.files.first;
        _mode = _BgMode.image;
      });
      _notifyChange();
    }
  }

  void _openColorPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => BgColorPicker(initialColor: _pickedColor),
    );
    if (result != null) {
      setState(() {
        _pickedColor = result['color'] as Color;
      });
      _notifyChange();
    }
  }

  void _notifyChange() {
    final Map<String, dynamic> payload = {'fond': null, 'fond_file': null};
    if (_mode == _BgMode.color) {
      payload['fond'] = _colorToHex(_pickedColor);
    } else if (_mode == _BgMode.image && _pickedImage != null) {
      payload['fond_file'] = _pickedImage;
    }
    widget.onChanged?.call(payload);
  }

  Widget _buildColorOption() {
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: _openColorPicker,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Couleur sélectionnée',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _colorToHex(_pickedColor),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _pickedImage?.bytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _pickedImage!.bytes!,
                    width: 96,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: 96,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_outlined, size: 26),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image sélectionnée',
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _pickedImage?.name ?? 'Aucune image',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final Color primary = isDarkMode
        ? Colors.blue.shade200
        : Colors.blue.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : icône + label + segmented button (utilise la couleur primaire du thème)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 20,
                    color: isDarkMode
                        ? Colors.blue.shade200
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Type de fond:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? Colors.blue.shade200
                          : Colors.blue.shade700,
                    ),
                  ),

                  Spacer(),

                  // Segmented button stylisé et plus large pour une décision intuitive
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 180,
                      maxWidth: 260,
                    ),
                    child: SegmentedButton<_BgMode>(
                      segments: [
                        ButtonSegment(
                          value: _BgMode.color,
                          icon: const Icon(Icons.palette),
                          label: const Text('Couleur'),
                        ),
                        ButtonSegment(
                          value: _BgMode.image,
                          icon: const Icon(Icons.image),
                          label: const Text('Image'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (Set<_BgMode> newSelection) {
                        setState(() {
                          _mode = newSelection.first;
                          if (_mode == _BgMode.color) _pickedImage = null;
                        });
                        // mise à jour automatique
                        _notifyChange();
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return primary;
                              }
                              return theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.08);
                            }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return Colors.grey;
                            }),

                        side: WidgetStateProperty.resolveWith<BorderSide?>((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return BorderSide(color: primary, width: 1);
                          }
                          return BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.4),
                            width: 1,
                          );
                        }),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        textStyle: WidgetStateProperty.all(
                          theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(WidgetState.pressed)) {
                            return primary.withOpacity(0.16);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return primary.withOpacity(0.06);
                          }
                          return null;
                        }),
                        elevation: WidgetStateProperty.resolveWith<double?>(
                          (states) =>
                              states.contains(WidgetState.selected) ? 1.8 : 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Options selon le type
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: BoxBorder.all(
              color: Colors.blueAccent.withAlpha(100),
              width: 1.4,
            ),
          ),
          child: _mode == _BgMode.color
              ? _buildColorOption()
              : _buildImageOption(),
        ),
      ],
    );
  }
}
