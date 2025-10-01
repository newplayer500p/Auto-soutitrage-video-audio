import 'package:flutter/material.dart';

/// -------------------- Helpers --------------------
String colorToHex(
  Color color, {
  bool leadingHash = true,
  bool includeAlpha = false,
}) {
  final a = includeAlpha ? color.alpha.toRadixString(16).padLeft(2, '0') : '';
  final r = color.red.toRadixString(16).padLeft(2, '0');
  final g = color.green.toRadixString(16).padLeft(2, '0');
  final b = color.blue.toRadixString(16).padLeft(2, '0');
  final hex = '$a$r$g$b'.toUpperCase();
  return (leadingHash ? '#' : '') + hex;
}

Color hexToColor(String hex) {
  var cleaned = hex.replaceAll('#', '').toUpperCase();
  if (cleaned.length == 3) {
    // short form like FFF -> FFFFFF
    cleaned = cleaned.split('').map((c) => c + c).join();
  }
  if (cleaned.length == 6) cleaned = 'FF$cleaned'; // add alpha
  if (cleaned.length != 8) throw FormatException('Invalid hex color: $hex');
  return Color(int.parse(cleaned, radix: 16));
}

/// Common palette (hex strings)
const List<String> commonHexColors = [
  '#FFFFFF', // white
  '#000000', // black
  '#FF0000', // red
  '#00FF00', // lime
  '#0000FF', // blue
  '#FFFF00', // yellow
  '#FF8800', // orange
  '#800080', // purple
  '#808080', // gray
  '#00FFFF', // cyan
  '#FFC0CB', // pink
  '#4CAF50', // material green
  '#2196F3', // material blue
];
