class Product {
  const Product({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.description,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    required this.imageQuadrant,
    required this.specifications,
    this.badge,
  });

  final String id;
  final String name;
  final String shortName;
  final String category;
  final String description;
  final double price;
  final double rating;
  final int reviewCount;
  final int stock;
  final int imageQuadrant;
  final Map<String, String> specifications;
  final String? badge;
}

const demoProducts = <Product>[
  Product(
    id: 'CHU-001',
    name: 'Churrasqueira Premium Aço',
    shortName: 'Churrasqueira Premium',
    category: 'Churrasqueiras',
    description: 'Churrasqueira em aço inox com tampa, termômetro e cinco níveis de grelha para um churrasco preciso.',
    price: 899.90,
    rating: 4.8,
    reviewCount: 127,
    stock: 10,
    imageQuadrant: 0,
    badge: 'MAIS VENDIDO',
    specifications: {
      'Material': 'Aço inox e ferro fundido',
      'Dimensões': '76 x 58 x 96 cm',
      'Peso': '18,4 kg',
      'Garantia': '12 meses',
    },
  ),
  Product(
    id: 'ESP-004',
    name: 'Espeto Giratório 4 Hastes',
    shortName: 'Espeto Giratório 4 hastes',
    category: 'Espetos',
    description: 'Conjunto giratório em aço inox com quatro hastes e motor bivolt de baixo ruído.',
    price: 249.90,
    rating: 4.7,
    reviewCount: 84,
    stock: 16,
    imageQuadrant: 1,
    specifications: {
      'Material': 'Aço inox 304',
      'Motor': 'Bivolt automático',
      'Capacidade': 'Até 8 kg',
      'Garantia': '12 meses',
    },
  ),
  Product(
    id: 'GRE-002',
    name: 'Grelha Dupla Ferro Fundido',
    shortName: 'Grelha Ferro Fundido',
    category: 'Grelhas',
    description: 'Chapa dupla de ferro fundido com alças térmicas, ideal para carnes, legumes e acompanhamentos.',
    price: 129.90,
    rating: 4.9,
    reviewCount: 96,
    stock: 22,
    imageQuadrant: 2,
    specifications: {
      'Material': 'Ferro fundido',
      'Dimensões': '45 x 30 cm',
      'Superfície': 'Dupla face',
      'Garantia': '6 meses',
    },
  ),
  Product(
    id: 'KIT-008',
    name: 'Kit Churrasco Profissional',
    shortName: 'Kit Churrasco Pro',
    category: 'Kits',
    description: 'Kit completo com espátula, pegador, garfo e pincel em estojo resistente para transporte.',
    price: 189.90,
    rating: 4.6,
    reviewCount: 63,
    stock: 8,
    imageQuadrant: 3,
    badge: 'ÚLTIMAS UNIDADES',
    specifications: {
      'Peças': '4 utensílios + estojo',
      'Material': 'Aço inox e silicone',
      'Cabos': 'Antitérmicos',
      'Garantia': '6 meses',
    },
  ),
];

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
