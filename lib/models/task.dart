class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime scheduledTime;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledTime,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'scheduledTime': scheduledTime.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        scheduledTime: DateTime.parse(map['scheduledTime']),
      );
}
