enum OrderStatus {
  pending,
  confirmed,
  preparing,
  shipped,
  delivered,
  cancelled,
  returned
}

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
    final itemsRaw = _firstNonNull(
      json,
      const ['items', 'order_items', 'orderItems', 'products', 'lines'],
    );
    final statusHistoryRaw = _firstNonNull(
      json,
      const ['status_history', 'statusHistory', 'tracking_history', 'history'],
    );

    return Order(
      id: _parseInt(
            _firstNonNull(
              json,
              const ['id', 'order_id', 'orderId', 'order_number', 'number'],
            ),
          ) ??
          0,
      customerId: _parseInt(
        _firstNonNull(json, const ['customer_id', 'customerId']),
      ),
      customerName: _firstNonNull(
            json,
            const ['customer_name', 'customerName', 'full_name', 'name'],
          ) as String? ??
          '',
      customerPhone: _firstNonNull(
            json,
            const ['customer_phone', 'customerPhone', 'phone', 'mobile'],
          ) as String? ??
          '',
      customerLocation: _firstNonNull(
            json,
            const [
              'customer_location',
              'customerLocation',
              'location',
              'address'
            ],
          ) as String? ??
          '',
      subtotal: _parseDouble(
        _firstNonNull(
          json,
          const ['subtotal', 'sub_total', 'items_subtotal', 'itemsSubtotal'],
        ),
      ),
      shippingFee: _parseDouble(
        _firstNonNull(
          json,
          const [
            'shipping_fee',
            'shippingFee',
            'delivery_fee',
            'deliveryFee',
            'shipping_cost',
            'base_fee',
          ],
        ),
      ),
      total: _parseDouble(
        _firstNonNull(
          json,
          const [
            'total',
            'total_amount',
            'totalAmount',
            'grand_total',
            'grandTotal',
            'final_total',
            'amount',
          ],
        ),
      ),
      status:
          _firstNonNull(json, const ['status', 'order_status', 'orderStatus'])
                  as String? ??
              'pending',
      notes: json['notes'] as String?,
      createdAt: _parseDateTime(
            _firstNonNull(
              json,
              const ['created_at', 'createdAt', 'order_date', 'date'],
            ),
          ) ??
          DateTime.now(),
      items: (itemsRaw is List)
          ? itemsRaw
              .whereType<Map>()
              .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      statusHistory: (statusHistoryRaw is List)
          ? statusHistoryRaw
              .whereType<Map>()
              .map((e) =>
                  OrderStatusHistory.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll('#', '').trim();
      return int.tryParse(cleaned);
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static dynamic _firstNonNull(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return json[key];
      }
    }
    return null;
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
    final productRaw = json['product'];
    final productMap =
        productRaw is Map ? Map<String, dynamic>.from(productRaw) : null;

    return OrderItem(
      id: Order._parseInt(
            Order._firstNonNull(json, const ['id', 'item_id', 'itemId']),
          ) ??
          0,
      productId: Order._parseInt(
            Order._firstNonNull(
              json,
              const ['product_id', 'productId'],
            ),
          ) ??
          Order._parseInt(productMap?['id']) ??
          0,
      productName: (Order._firstNonNull(
                json,
                const ['product_name', 'productName', 'name', 'title'],
              ) ??
              productMap?['name_en'] ??
              productMap?['name_ar'] ??
              productMap?['name']) as String? ??
          '',
      productImage: (Order._firstNonNull(
            json,
            const ['product_image', 'productImage', 'image', 'image_url'],
          ) ??
          productMap?['image_url'] ??
          productMap?['image']) as String?,
      quantity: Order._parseInt(
            Order._firstNonNull(json, const ['quantity', 'qty', 'count']),
          ) ??
          1,
      unitPrice: Order._parseDouble(
        Order._firstNonNull(
              json,
              const ['unit_price', 'unitPrice', 'price'],
            ) ??
            productMap?['price'],
      ),
      subtotal: Order._parseDouble(
        Order._firstNonNull(
              json,
              const ['subtotal', 'line_total', 'lineTotal', 'total'],
            ) ??
            productMap?['price'],
      ),
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
      id: Order._parseInt(
              Order._firstNonNull(json, const ['id', 'history_id'])) ??
          0,
      status: (Order._firstNonNull(json, const ['status', 'order_status'])
              as String?) ??
          'pending',
      notes: json['notes'] as String?,
      changedAt: Order._parseDateTime(
            Order._firstNonNull(
                json, const ['changed_at', 'changedAt', 'created_at']),
          ) ??
          DateTime.now(),
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
