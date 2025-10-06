// task_tile_design.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:front_end/services/task_model.dart';

class TaskTileDesign extends StatelessWidget {
  final Task task;
  final VoidCallback onDownload;

  const TaskTileDesign({
    super.key,
    required this.task,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: ListTile(
        leading: _buildStatusIcon(),
        title: Text(
          task.label,
          style: TextStyle(fontWeight: FontWeight.w500, color: _getTextColor()),
        ),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (task.status) {
      case 'done':
        return Colors.green[50]!;
      case 'error':
        return Colors.red[50]!;
      case 'in_progress':
        return Colors.blue[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  Color _getBorderColor() {
    switch (task.status) {
      case 'done':
        return Colors.green[100]!;
      case 'error':
        return Colors.red[100]!;
      case 'in_progress':
        return Colors.blue[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getTextColor() {
    switch (task.status) {
      case 'done':
        return Colors.green[800]!;
      case 'error':
        return Colors.red[800]!;
      case 'in_progress':
        return Colors.blue[800]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildStatusIcon() {
    switch (task.status) {
      case 'pending':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.schedule, size: 20, color: Colors.grey),
        );
      case 'in_progress':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        );
      case 'done':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: 20, color: Colors.green),
        );
      case 'error':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error, size: 20, color: Colors.red),
        );
      default:
        return Icon(Icons.circle, size: 20);
    }
  }

  Widget? _buildSubtitle() {
    final subtitle = _subtitleTextFromInfo(task.info);
    if (subtitle == null) return null;

    return Text(
      subtitle,
      style: TextStyle(color: _getTextColor().withOpacity(0.7), fontSize: 12),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTrailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_shouldShowDownload(task))
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.download, size: 16, color: Colors.white),
            ),
            onPressed: onDownload,
            tooltip: "Télécharger",
          ),
        if (task.status == 'in_progress')
          Text(
            "En cours...",
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  bool _shouldShowDownload(Task task) {
    return task.status == 'done' &&
        (task.download || _looksLikePath(task.info));
  }

  bool _looksLikePath(dynamic info) {
    if (info is String) {
      return info.contains("/uploads") || info.startsWith("/");
    }
    return false;
  }

  String? _subtitleTextFromInfo(dynamic info) {
    if (info == null) return null;
    if (info is String) return info;
    try {
      return jsonEncode(info);
    } catch (_) {
      return info.toString();
    }
  }
}
