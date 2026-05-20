class Coupon {
  final String id;
  final String title;
  final String description;
  final String category; // 'café', 'tienda', 'evento', 'comida'
  final int costInCoins;
  final String discount; // '20% descuento', '1 bebida gratis', etc.
  final String businessName;
  final String location; // 'Chapinero', 'Usaquén', 'La Candelaria'
  final String imageEmoji; // ☕, 🛍️, 🎭, 🍕
  final DateTime expiryDate;
  bool isRedeemed;

  Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.costInCoins,
    required this.discount,
    required this.businessName,
    required this.location,
    required this.imageEmoji,
    required this.expiryDate,
    this.isRedeemed = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  // Para mostrar días restantes hasta expiración
  int get daysUntilExpiry {
    final difference = expiryDate.difference(DateTime.now());
    return difference.inDays;
  }

  // Método para canjear
  void redeem() {
    isRedeemed = true;
  }

  @override
  String toString() =>
      'Coupon(id: $id, title: $title, costInCoins: $costInCoins, isRedeemed: $isRedeemed)';
}
