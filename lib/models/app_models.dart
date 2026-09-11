enum OrderStatus {
  received,
  paymentApproved,
  preparing,
  shipped,
  delivered,
  cancelled,
}

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.received => 'Pedido recebido',
    OrderStatus.paymentApproved => 'Pagamento aprovado',
    OrderStatus.preparing => 'Em preparação',
    OrderStatus.shipped => 'Em transporte',
    OrderStatus.delivered => 'Entregue',
    OrderStatus.cancelled => 'Cancelado',
  };
}

enum QuoteStatus { pending, reviewing, approved, rejected, answered }

extension QuoteStatusLabel on QuoteStatus {
  String get label => switch (this) {
    QuoteStatus.pending => 'Pendente',
    QuoteStatus.reviewing => 'Em análise',
    QuoteStatus.approved => 'Aprovado',
    QuoteStatus.rejected => 'Recusado',
    QuoteStatus.answered => 'Respondido',
  };
}

enum ProductSort { relevance, name, priceLowToHigh, priceHighToLow, rating }

extension ProductSortLabel on ProductSort {
  String get label => switch (this) {
    ProductSort.relevance => 'Relevância',
    ProductSort.name => 'Nome',
    ProductSort.priceLowToHigh => 'Menor preço',
    ProductSort.priceHighToLow => 'Maior preço',
    ProductSort.rating => 'Melhor avaliação',
  };
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  return values.cast<T>().firstWhere(
    (value) => value.name == name,
    orElse: () => fallback,
  );
}

DateTime _date(Object? value, [DateTime? fallback]) {
  return DateTime.tryParse(value?.toString() ?? '') ??
      fallback ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.passwordHash,
    required this.createdAt,
    this.blocked = false,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String passwordHash;
  final DateTime createdAt;
  final bool blocked;

  bool get isAdmin => role.toLowerCase() == 'admin';

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? passwordHash,
    DateTime? createdAt,
    bool? blocked,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      blocked: blocked ?? this.blocked,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'passwordHash': passwordHash,
    'createdAt': createdAt.toIso8601String(),
    'blocked': blocked,
  };

  factory AppUser.fromJson(Map<String, Object?> json) => AppUser(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    role: json['role']?.toString() ?? 'customer',
    passwordHash: json['passwordHash']?.toString() ?? '',
    createdAt: _date(json['createdAt']),
    blocked: json['blocked'] == true,
  );
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.postalCode,
    this.complement = '',
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  String get formatted {
    final extra = complement.trim().isEmpty ? '' : ', $complement';
    return '$street, $number$extra · $neighborhood · $city/$state';
  }

  Address copyWith({
    String? id,
    String? label,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? postalCode,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'street': street,
    'number': number,
    'complement': complement,
    'neighborhood': neighborhood,
    'city': city,
    'state': state,
    'postalCode': postalCode,
    'isDefault': isDefault,
  };

  factory Address.fromJson(Map<String, Object?> json) => Address(
    id: json['id']?.toString() ?? '',
    label: json['label']?.toString() ?? 'Endereço',
    street: json['street']?.toString() ?? '',
    number: json['number']?.toString() ?? '',
    complement: json['complement']?.toString() ?? '',
    neighborhood: json['neighborhood']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    state: json['state']?.toString() ?? '',
    postalCode: json['postalCode']?.toString() ?? '',
    isDefault: json['isDefault'] == true,
  );
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.imageQuadrant,
  });

  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final int imageQuadrant;

  double get total => unitPrice * quantity;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'imageQuadrant': imageQuadrant,
  };

  factory OrderItem.fromJson(Map<String, Object?> json) => OrderItem(
    productId: json['productId']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    imageQuadrant: (json['imageQuadrant'] as num?)?.toInt() ?? 0,
  );
}

class OrderTimelineEntry {
  const OrderTimelineEntry({
    required this.status,
    required this.title,
    required this.note,
    required this.createdAt,
  });

  final OrderStatus status;
  final String title;
  final String note;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'status': status.name,
    'title': title,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OrderTimelineEntry.fromJson(Map<String, Object?> json) =>
      OrderTimelineEntry(
        status: _enumByName(
          OrderStatus.values,
          json['status'],
          OrderStatus.received,
        ),
        title: json['title']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
        createdAt: _date(json['createdAt']),
      );
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.total,
    required this.paymentMethod,
    required this.deliveryAddress,
    this.status = OrderStatus.received,
    this.timeline = const [],
  });

  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double shipping;
  final double total;
  final String paymentMethod;
  final Address deliveryAddress;
  final OrderStatus status;
  final List<OrderTimelineEntry> timeline;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CustomerOrder copyWith({
    String? id,
    DateTime? createdAt,
    List<OrderItem>? items,
    double? subtotal,
    double? discount,
    double? shipping,
    double? total,
    String? paymentMethod,
    Address? deliveryAddress,
    OrderStatus? status,
    List<OrderTimelineEntry>? timeline,
  }) {
    return CustomerOrder(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      shipping: shipping ?? this.shipping,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'shipping': shipping,
    'total': total,
    'paymentMethod': paymentMethod,
    'deliveryAddress': deliveryAddress.toJson(),
    'status': status.name,
    'timeline': timeline.map((item) => item.toJson()).toList(),
  };

  factory CustomerOrder.fromJson(Map<String, Object?> json) => CustomerOrder(
    id: json['id']?.toString() ?? '',
    createdAt: _date(json['createdAt']),
    items: _mapList(json['items'], OrderItem.fromJson),
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0,
    shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    paymentMethod: json['paymentMethod']?.toString() ?? '',
    deliveryAddress: Address.fromJson(_map(json['deliveryAddress'])),
    status: _enumByName(
      OrderStatus.values,
      json['status'],
      OrderStatus.received,
    ),
    timeline: _mapList(json['timeline'], OrderTimelineEntry.fromJson),
  );
}

class QuoteRequest {
  const QuoteRequest({
    required this.id,
    required this.productId,
    required this.productName,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.details,
    required this.createdAt,
    this.status = QuoteStatus.pending,
    this.response,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String customerName;
  final String email;
  final String phone;
  final String details;
  final DateTime createdAt;
  final QuoteStatus status;
  final String? response;
  final DateTime? updatedAt;

  QuoteRequest copyWith({
    String? id,
    String? productId,
    String? productName,
    String? customerName,
    String? email,
    String? phone,
    String? details,
    DateTime? createdAt,
    QuoteStatus? status,
    String? response,
    DateTime? updatedAt,
  }) {
    return QuoteRequest(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      customerName: customerName ?? this.customerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      response: response ?? this.response,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'customerName': customerName,
    'email': email,
    'phone': phone,
    'details': details,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'response': response,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory QuoteRequest.fromJson(Map<String, Object?> json) => QuoteRequest(
    id: json['id']?.toString() ?? '',
    productId: json['productId']?.toString() ?? '',
    productName: json['productName']?.toString() ?? '',
    customerName: json['customerName']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    details: json['details']?.toString() ?? '',
    createdAt: _date(json['createdAt']),
    status: _enumByName(
      QuoteStatus.values,
      json['status'],
      QuoteStatus.pending,
    ),
    response: json['response']?.toString(),
    updatedAt: json['updatedAt'] == null ? null : _date(json['updatedAt']),
  );
}

class Coupon {
  const Coupon({
    required this.code,
    required this.description,
    required this.discountPercent,
    this.minimumSubtotal = 0,
    this.expiresAt,
    this.active = true,
    this.usageLimit,
    this.usedCount = 0,
  });

  final String code;
  final String description;
  final double discountPercent;
  final double minimumSubtotal;
  final DateTime? expiresAt;
  final bool active;
  final int? usageLimit;
  final int usedCount;

  bool isAvailable({DateTime? at, double subtotal = 0}) {
    final now = at ?? DateTime.now();
    return active &&
        subtotal >= minimumSubtotal &&
        (expiresAt == null || !expiresAt!.isBefore(now)) &&
        (usageLimit == null || usedCount < usageLimit!);
  }

  Coupon copyWith({
    String? code,
    String? description,
    double? discountPercent,
    double? minimumSubtotal,
    DateTime? expiresAt,
    bool? active,
    int? usageLimit,
    int? usedCount,
  }) {
    return Coupon(
      code: code ?? this.code,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      minimumSubtotal: minimumSubtotal ?? this.minimumSubtotal,
      expiresAt: expiresAt ?? this.expiresAt,
      active: active ?? this.active,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
    );
  }

  Map<String, Object?> toJson() => {
    'code': code,
    'description': description,
    'discountPercent': discountPercent,
    'minimumSubtotal': minimumSubtotal,
    'expiresAt': expiresAt?.toIso8601String(),
    'active': active,
    'usageLimit': usageLimit,
    'usedCount': usedCount,
  };

  factory Coupon.fromJson(Map<String, Object?> json) => Coupon(
    code: json['code']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
    minimumSubtotal: (json['minimumSubtotal'] as num?)?.toDouble() ?? 0,
    expiresAt: json['expiresAt'] == null ? null : _date(json['expiresAt']),
    active: json['active'] != false,
    usageLimit: (json['usageLimit'] as num?)?.toInt(),
    usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
  );
}

class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.startAt,
    this.endAt,
    this.active = true,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool active;

  Campaign copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    DateTime? startAt,
    DateTime? endAt,
    bool? active,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      active: active ?? this.active,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'startAt': startAt?.toIso8601String(),
    'endAt': endAt?.toIso8601String(),
    'active': active,
  };

  factory Campaign.fromJson(Map<String, Object?> json) => Campaign(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
    createdAt: _date(json['createdAt']),
    startAt: json['startAt'] == null ? null : _date(json['startAt']),
    endAt: json['endAt'] == null ? null : _date(json['endAt']),
    active: json['active'] != false,
  );
}

class NotificationPreferences {
  const NotificationPreferences({
    this.orderUpdates = true,
    this.offers = true,
    this.support = true,
  });

  final bool orderUpdates;
  final bool offers;
  final bool support;

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? offers,
    bool? support,
  }) => NotificationPreferences(
    orderUpdates: orderUpdates ?? this.orderUpdates,
    offers: offers ?? this.offers,
    support: support ?? this.support,
  );

  Map<String, Object?> toJson() => {
    'orderUpdates': orderUpdates,
    'offers': offers,
    'support': support,
  };

  factory NotificationPreferences.fromJson(Map<String, Object?> json) =>
      NotificationPreferences(
        orderUpdates: json['orderUpdates'] != false,
        offers: json['offers'] != false,
        support: json['support'] != false,
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String message;
  final String category;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    DateTime? createdAt,
    bool? read,
  }) => AppNotification(
    id: id ?? this.id,
    title: title ?? this.title,
    message: message ?? this.message,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    read: read ?? this.read,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, Object?> json) =>
      AppNotification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        category: json['category']?.toString() ?? 'system',
        createdAt: _date(json['createdAt']),
        read: json['read'] == true,
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.fromUser,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final bool fromUser;

  String get time {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'fromUser': fromUser,
  };

  factory ChatMessage.fromJson(Map<String, Object?> json) => ChatMessage(
    id: json['id']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
    createdAt: _date(json['createdAt']),
    fromUser: json['fromUser'] == true,
  );
}

class DeliveryEstimate {
  const DeliveryEstimate({
    required this.postalCode,
    required this.cost,
    required this.estimatedStart,
    required this.estimatedEnd,
  });

  final String postalCode;
  final double cost;
  final DateTime estimatedStart;
  final DateTime estimatedEnd;
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, Object?>{};
}

List<T> _mapList<T>(Object? value, T Function(Map<String, Object?>) decode) {
  if (value is! List) return <T>[];
  return value.map((item) => decode(_map(item))).toList();
}
