class Task {
  final String id;
  final String label;
  String status;
  dynamic info;
  dynamic data;
  bool download;

  Task({
    required this.id,
    required this.label,
    this.status = 'pending',
    this.info,
    this.data,
    this.download = false,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      label: map['label'] as String,
      status: map['status'] ?? 'pending',
      info: map['info'],
      data: map['data'],
      download: map['download'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'status': status,
      'info': info,
      'data': data,
      'download': download,
    };
  }
}
