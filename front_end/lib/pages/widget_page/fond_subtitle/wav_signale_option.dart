import 'package:flutter/material.dart';
import 'package:front_end/pages/widget_page/fond_subtitle/choix_wav_signal_video.dart';

class WavSignaleOption extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  final bool waveForm;
  const WavSignaleOption({
    super.key,
    required this.onChanged,
    required this.waveForm,
  });

  @override
  State<WavSignaleOption> createState() => _WavSignaleOptionState();
}

class _WavSignaleOptionState extends State<WavSignaleOption> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.graphic_eq_sharp,
                size: 20,
                color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Options du fond:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Waveform Option
        WaveformOption(
          value: widget.waveForm,
          onChanged: widget.onChanged,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
}
