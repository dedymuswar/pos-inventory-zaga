class CartItem {
  final int productId;
  final String name;
  final int price;
  final int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.qty = 1,
  });

  int get total => price * qty;
}