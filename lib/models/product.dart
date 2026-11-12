class Product {
  const Product({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.description,
    required this.price,
    required this.stock,
    this.images = const [],
    this.specifications = const {},
    this.measures = const [],
    this.voltageOptions = const [],
    this.promotionalPrice,
    this.pixPrice,
    this.installments,
    this.installmentValue,
    this.videoUrl,
    this.url,
    this.badge,
    this.active = true,
  });

  final String id;
  final String name;
  final String shortName;
  final String category;
  final String description;

  /// Preço de tabela publicado no site (R\$).
  final double price;

  /// Preço promocional, quando o site anuncia um.
  final double? promotionalPrice;

  /// Valor à vista no Pix informado pelo site.
  final double? pixPrice;

  /// Parcelamento no cartão informado pelo site (ex.: 12x de R\$ 48,21).
  final int? installments;
  final double? installmentValue;
  final int stock;

  /// Caminhos de assets (ex.: assets/images/products/ID-1.jpg).
  final List<String> images;
  final Map<String, String> specifications;

  /// Medidas e detalhes técnicos descritos em texto livre no site.
  final List<String> measures;

  /// Opções de voltagem quando o cliente precisa escolher (ex.: 127V/220V).
  final List<String> voltageOptions;
  final String? videoUrl;

  /// Página do produto no site oficial.
  final String? url;
  final String? badge;
  final bool active;

  bool get inStock => stock > 0;
  String? get coverImage => images.isEmpty ? null : images.first;

  /// Preço efetivo usado no carrinho (promoção, quando houver).
  double get salePrice => promotionalPrice != null && promotionalPrice! < price
      ? promotionalPrice!
      : price;

  Product copyWith({
    String? id,
    String? name,
    String? shortName,
    String? category,
    String? description,
    double? price,
    int? stock,
    List<String>? images,
    Map<String, String>? specifications,
    List<String>? measures,
    List<String>? voltageOptions,
    double? promotionalPrice,
    double? pixPrice,
    int? installments,
    double? installmentValue,
    String? videoUrl,
    String? url,
    String? badge,
    bool? active,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      specifications: specifications ?? this.specifications,
      measures: measures ?? this.measures,
      voltageOptions: voltageOptions ?? this.voltageOptions,
      promotionalPrice: promotionalPrice ?? this.promotionalPrice,
      pixPrice: pixPrice ?? this.pixPrice,
      installments: installments ?? this.installments,
      installmentValue: installmentValue ?? this.installmentValue,
      videoUrl: videoUrl ?? this.videoUrl,
      url: url ?? this.url,
      badge: badge ?? this.badge,
      active: active ?? this.active,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'category': category,
    'description': description,
    'price': price,
    'stock': stock,
    'images': images,
    'specifications': specifications,
    'measures': measures,
    'voltageOptions': voltageOptions,
    'promotionalPrice': promotionalPrice,
    'pixPrice': pixPrice,
    'installments': installments,
    'installmentValue': installmentValue,
    'videoUrl': videoUrl,
    'url': url,
    'badge': badge,
    'active': active,
  };

  factory Product.fromJson(Map<String, Object?> json) {
    final rawSpecifications = json['specifications'];
    final specifications = <String, String>{};
    if (rawSpecifications is Map) {
      for (final entry in rawSpecifications.entries) {
        specifications[entry.key.toString()] = entry.value.toString();
      }
    }
    List<String> strings(Object? value) =>
        value is List ? value.map((item) => item.toString()).toList() : [];
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['shortName']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Outros',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      images: strings(json['images']),
      specifications: specifications,
      measures: strings(json['measures']),
      voltageOptions: strings(json['voltageOptions']),
      promotionalPrice: (json['promotionalPrice'] as num?)?.toDouble(),
      pixPrice: (json['pixPrice'] as num?)?.toDouble(),
      installments: (json['installments'] as num?)?.toInt(),
      installmentValue: (json['installmentValue'] as num?)?.toDouble(),
      videoUrl: json['videoUrl']?.toString(),
      url: json['url']?.toString(),
      badge: json['badge']?.toString(),
      active: json['active'] != false,
    );
  }
}

String money(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  final parts = fixed.split(',');
  final digits = parts.first;
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      grouped.write('.');
    }
    grouped.write(digits[index]);
  }
  return 'R\$ ${grouped.toString()},${parts.last}';
}
