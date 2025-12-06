class ShippingSettings {
  final double shippingFee;
  final double freeShippingThreshold;

  ShippingSettings({
    required this.shippingFee,
    required this.freeShippingThreshold,
  });

  factory ShippingSettings.fromJson(Map<String, dynamic> json) {
    return ShippingSettings(
      shippingFee: _parseDouble(json['shipping_fee'] ?? json['shippingFee']),
      freeShippingThreshold: _parseDouble(json['free_shipping_threshold'] ?? json['freeShippingThreshold']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double calculateShipping(double subtotal) {
    if (freeShippingThreshold > 0 && subtotal >= freeShippingThreshold) {
      return 0;
    }
    return shippingFee;
  }
}
