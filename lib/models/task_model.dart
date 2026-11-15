enum TaskStatus { todo, inProgress, completed }

enum TaskPriority { low, medium, high }

class TaskModel {
  TaskModel({
    required this.title,
    required this.subject,
    required this.deadline,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
  });

  final String title;
  final String subject;
  final DateTime deadline;
  final String description;
  final TaskPriority priority;
  TaskStatus status;
}
