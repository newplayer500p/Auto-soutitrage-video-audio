class Task {
  final String id;
  final String label;
  String status; // pending, in_progress, done, error
  Map<String, dynamic>? info;

  Task({
    required this.id,
    required this.label,
    this.status = 'pending',
    this.info,
  });
  factory Task.fromMap(Map m) => Task(
    id: m['id'],
    label: m['label'],
    status: m['status'] ?? 'pending',
    info: (m['info'] as Map?)?.cast<String, dynamic>(),
  );
}
