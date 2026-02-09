enum OrderStatus { pending, confirmed, preparing, shipped, delivered, cancelled, returned }

class Order {
  final int id;
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final String customerLocation;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final List<OrderItem> items;
  final List<OrderStatusHistory> statusHistory;

  Order({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerLocation,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    this.notes,
    required this.createdAt,
    this.items = const [],
    this.statusHistory = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      customerId: json['customer_id'] != null 
          ? (json['customer_id'] is String ? int.parse(json['customer_id']) : json['customer_id'] as int)
          : null,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerLocation: json['customer_location'] as String? ?? '',
      subtotal: _parseDouble(json['subtotal']),
      shippingFee: _parseDouble(json['shipping_fee']),
      total: _parseDouble(json['total']),
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      statusHistory: (json['statusHistory'] as List<dynamic>?)
          ?.map((e) => OrderStatusHistory.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get statusAr {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'تم التأكيد';
      case 'preparing':
        return 'قيد التحضير';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      case 'returned':
        return 'مرتجع';
      default:
        return status;
    }
  }
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      productId: json['product_id'] is String ? int.parse(json['product_id']) : json['product_id'] as int,
      productName: json['product_name'] as String? ?? json['name'] as String? ?? '',
      productImage: json['product_image'] as String? ?? json['image'] as String?,
      quantity: json['quantity'] is String ? int.parse(json['quantity']) : json['quantity'] as int,
      unitPrice: Order._parseDouble(json['unit_price'] ?? json['price']),
      subtotal: Order._parseDouble(json['subtotal']),
    );
  }
}

class OrderStatusHistory {
  final int id;
  final String status;
  final String? notes;
  final DateTime changedAt;
  final String? changedByName;

  OrderStatusHistory({
    required this.id,
    required this.status,
    this.notes,
    required this.changedAt,
    this.changedByName,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      changedAt: DateTime.parse(json['changed_at'] as String),
      changedByName: json['changed_by_name'] as String?,
    );
  }

  String get statusAr {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'تم التأكيد';
      case 'preparing':
        return 'قيد التحضير';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      case 'returned':
        return 'مرتجع';
      default:
        return status;
    }
  }
}
