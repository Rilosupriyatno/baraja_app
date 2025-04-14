class Topping {
  final String id;
  final String name;
  final double price;

  Topping({
    required this.id,
    required this.name,
    required this.price,
  });

  factory Topping.fromJson(Map<String, dynamic> json) {
    return Topping(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] != null) ? json['price'].toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
    };
  }
}
