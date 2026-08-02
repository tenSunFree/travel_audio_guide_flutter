class Reminder {
  const Reminder({
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.targetTime,
    required this.remindBeforeSeconds,
    required this.notifyTime,
    required this.notificationId,
    required this.routePath,
    required this.payloadJson,
    required this.isEnabled,
    required this.isDone,
    required this.createdAt,
    this.id,
    this.subtitle,
    this.imageUrl,
    this.address,
    this.updatedAt,
  });

  final int? id;
  final String sourceType;
  final String sourceId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? address;
  final DateTime targetTime;
  final int remindBeforeSeconds;
  final DateTime notifyTime;
  final int notificationId;
  final String routePath;
  final String payloadJson;
  final bool isEnabled;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isExpired => notifyTime.isBefore(DateTime.now());
}
