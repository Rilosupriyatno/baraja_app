class Addon {
  final String name;
  final String type;
  final List<AddonOption> options;

  Addon({required this.name, required this.type, required this.options});

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      name: json['name'],
      type: json['type'],
      options: (json['options'] as List)
          .map((o) => AddonOption.fromJson(o))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class AddonOption {
  final String label;
  final double price;

  AddonOption({required this.label, required this.price});

  factory AddonOption.fromJson(Map<String, dynamic> json) {
    return AddonOption(
      label: json['label'],
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'price': price,
    };
  }
}
