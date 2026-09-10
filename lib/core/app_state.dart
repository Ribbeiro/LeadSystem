import 'package:flutter/material.dart';

import '../models/product.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.time,
    required this.fromUser,
  });

  final String text;
  final String time;
  final bool fromUser;
}

class AppState extends ChangeNotifier {
  final Map<String, int> _cart = {};
  final Set<String> _favorites = {};
  final List<ChatMessage> _messages = [
    const ChatMessage(
      text: 'Olá! Como posso ajudar com seu pedido?',
      time: '14:29',
      fromUser: false,
    ),
    const ChatMessage(
      text: 'Quero acompanhar o pedido #SG-2026-0147.',
      time: '14:31',
      fromUser: true,
    ),
  ];

  int navigationIndex = 0;
  String searchQuery = '';
  String category = 'Todos';
  bool couponApplied = false;
  bool loggedIn = false;
  bool orderPlaced = false;
  String userName = 'Leandro Gonçalves';

  Map<String, int> get cart => Map.unmodifiable(_cart);
  Set<String> get favorites => Set.unmodifiable(_favorites);
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  int get cartCount => _cart.values.fold(0, (sum, value) => sum + value);

  double get subtotal => _cart.entries.fold(0, (sum, entry) {
    final product = productById(entry.key);
    return sum + product.price * entry.value;
  });

  double get discount => couponApplied ? subtotal * .10 : 0;
  double get shipping => _cart.isEmpty ? 0 : 24.90;
  double get total => subtotal - discount + shipping;

  List<Product> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();
    return demoProducts.where((product) {
      final matchesCategory =
          category == 'Todos' || product.category == category;
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Product productById(String id) =>
      demoProducts.firstWhere((item) => item.id == id);

  void setNavigationIndex(int value) {
    navigationIndex = value;
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  void addToCart(Product product, {int quantity = 1}) {
    _cart.update(
      product.id,
      (value) => value + quantity,
      ifAbsent: () => quantity,
    );
    notifyListeners();
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _cart.remove(productId);
    } else {
      _cart[productId] = quantity;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    couponApplied = false;
    notifyListeners();
  }

  bool applyCoupon(String code) {
    couponApplied = code.trim().toUpperCase() == 'PRIMEIRACOMPRA';
    notifyListeners();
    return couponApplied;
  }

  void toggleFavorite(String productId) {
    if (!_favorites.add(productId)) {
      _favorites.remove(productId);
    }
    notifyListeners();
  }

  void signIn({String? name}) {
    loggedIn = true;
    if (name != null && name.trim().isNotEmpty) {
      userName = name.trim();
    }
    notifyListeners();
  }

  void signOut() {
    loggedIn = false;
    notifyListeners();
  }

  void placeOrder() {
    orderPlaced = true;
    _cart.clear();
    couponApplied = false;
    notifyListeners();
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _messages.add(
      ChatMessage(text: text.trim(), time: 'agora', fromUser: true),
    );
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required AppState notifier, required super.child, super.key})
    : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore de widgets.');
    return scope!.notifier!;
  }
}
