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
  DateTime? redeemedDate; // Fecha cuando se canjeó
  String? couponCode; // Código único generado al canjear

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
    this.redeemedDate,
    this.couponCode,
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
    redeemedDate = DateTime.now();
    // Generar código único: formato COUPON-TIMESTAMP-RANDOM
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    couponCode = 'CPN-${id.toUpperCase()}-$random';
  }

  // Vigencia de cupón redimido (30 días desde redención)
  DateTime? get redemptionExpiryDate {
    if (redeemedDate == null) return null;
    return redeemedDate!.add(const Duration(days: 30));
  }

  // Días restantes de vigencia (desde redención)
  int? get daysRemainingAfterRedemption {
    if (redeemedDate == null) return null;
    final expiryDate = redeemedDate!.add(const Duration(days: 30));
    final difference = expiryDate.difference(DateTime.now());
    return difference.inDays;
  }

  // ¿Está vencido el cupón redimido?
  bool get isRedeemedCouponExpired {
    if (redeemedDate == null) return false;
    final expiryDate = redeemedDate!.add(const Duration(days: 30));
    return DateTime.now().isAfter(expiryDate);
  }

  @override
  String toString() =>
      'Coupon(id: $id, title: $title, costInCoins: $costInCoins, isRedeemed: $isRedeemed, code: $couponCode)';
}
