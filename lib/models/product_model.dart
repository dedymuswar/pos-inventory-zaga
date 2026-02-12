class Product {
  final int? id;
  final String barcode;
  final String name ;
  final double price;
  final int stock;
  final String category;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
    };
  }
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product( 
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      price: map['price'],
      stock: map['stock'],
      category: map['category'],
    );
  }
}
