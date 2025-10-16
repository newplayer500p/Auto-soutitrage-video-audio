// lib/widgets/top_nav_bar.dart
import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onRouteChanged;

  const TopNavBar({
    super.key,
    required this.currentRoute,
    required this.onRouteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    final items = [
      {
        'label': 'Traitement',
        'route': '/processing',
        'icon': Icons.play_circle_outline,
      },
      {'label': 'Historique', 'route': '/history', 'icon': Icons.history},
      {'label': 'Upload', 'route': '/upload', 'icon': Icons.file_upload},
    ];

    // Version mobile
    if (isSmall) {
      return Container(
        height: 50,
        color: Colors.grey[100],
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Text(
              'Sous-titrage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.grey),
              onSelected: onRouteChanged,
              itemBuilder: (_) => items
                  .map(
                    (it) => PopupMenuItem<String>(
                      value: it['route'] as String,
                      child: Row(
                        children: [
                          Icon(
                            it['icon'] as IconData,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            it['label'] as String,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }

    // Version desktop
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Text(
            'Sous-titrage',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 32),
          for (final it in items) ...[
            _NavButton(
              label: it['label'] as String,
              icon: it['icon'] as IconData,
              routeName: it['route'] as String,
              active: (currentRoute == it['route']),
              onTap: onRouteChanged,
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String routeName;
  final bool active;
  final Function(String) onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.routeName,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(routeName),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: active
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.blue[700]!, width: 2),
                  ),
                )
              : null,
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.blue[700] : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: active ? Colors.blue[700] : Colors.grey[600],
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
