class AppNotification {
  final int id;
  final int customerId;
  final int? orderId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.customerId,
    this.orderId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      customerId: json['customer_id'] is String ? int.parse(json['customer_id']) : json['customer_id'] as int,
      orderId: json['order_id'] != null 
          ? (json['order_id'] is String ? int.parse(json['order_id']) : json['order_id'] as int)
          : null,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get typeIcon {
    switch (type) {
      case 'order_confirmation':
        return '🛍️';
      case 'order_shipped':
        return '🚚';
      case 'order_delivered':
        return '✅';
      case 'order_cancelled':
        return '❌';
      default:
        return '📦';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}
