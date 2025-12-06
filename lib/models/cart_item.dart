import 'product.dart';

class CartItem {
  final int productId;
  final Product product;
  int quantity;

  CartItem({
    required this.productId,
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.displayPrice * quantity;

  CartItem copyWith({
    int? productId,
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
