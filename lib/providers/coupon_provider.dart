import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/coupon.dart';

class CouponProvider extends ChangeNotifier {
  static final logger = Logger();

  late List<Coupon> _availableCoupons = [];
  late List<Coupon> _redeemedCoupons = [];

  List<Coupon> get availableCoupons => _availableCoupons;
  List<Coupon> get redeemedCoupons => _redeemedCoupons;

  CouponProvider() {
    _initializeCoupons();
  }

  void _initializeCoupons() {
    final now = DateTime.now();
    
    _availableCoupons = [
      // Cafés
      Coupon(
        id: 'cafe_1',
        title: 'Café Gratis',
        description: 'Un café de cualquier tamaño',
        category: 'café',
        costInCoins: 50,
        discount: 'Bebida gratis',
        businessName: 'Café Chapinero Roasters',
        location: 'Chapinero',
        imageEmoji: '☕',
        expiryDate: now.add(Duration(days: 30)),
      ),
      Coupon(
        id: 'cafe_2',
        title: '20% en Desserts',
        description: 'Descuento en postres y pasteles',
        category: 'café',
        costInCoins: 35,
        discount: '20% descuento',
        businessName: 'Sweet Moments Bakery',
        location: 'Usaquén',
        imageEmoji: '🧁',
        expiryDate: now.add(Duration(days: 25)),
      ),
      Coupon(
        id: 'cafe_3',
        title: 'Combo Desayuno',
        description: 'Café + Pan tostado + Mermelada',
        category: 'café',
        costInCoins: 60,
        discount: 'Combo completo',
        businessName: 'Desayunos del Barrio',
        location: 'La Candelaria',
        imageEmoji: '🥐',
        expiryDate: now.add(Duration(days: 28)),
      ),
      
      // Tiendas
      Coupon(
        id: 'store_1',
        title: '30% en Ropa',
        description: 'Descuento en colección casual',
        category: 'tienda',
        costInCoins: 100,
        discount: '30% descuento',
        businessName: 'Moda Local Co.',
        location: 'Chapinero',
        imageEmoji: '👕',
        expiryDate: now.add(Duration(days: 35)),
      ),
      Coupon(
        id: 'store_2',
        title: '2x1 en Libros',
        description: 'Lleva 2 libros y paga 1',
        category: 'tienda',
        costInCoins: 80,
        discount: '2x1 en libros',
        businessName: 'Librería Página Blanca',
        location: 'Usaquén',
        imageEmoji: '📚',
        expiryDate: now.add(Duration(days: 30)),
      ),
      Coupon(
        id: 'store_3',
        title: 'Accesorios al 25%',
        description: 'Mochilas, gorras y más',
        category: 'tienda',
        costInCoins: 45,
        discount: '25% descuento',
        businessName: 'Accesorio Indie',
        location: 'La Candelaria',
        imageEmoji: '🎒',
        expiryDate: now.add(Duration(days: 20)),
      ),

      // Comida
      Coupon(
        id: 'food_1',
        title: 'Almuerzo Ejecutivo',
        description: 'Almuerzo + Bebida + Postre',
        category: 'comida',
        costInCoins: 120,
        discount: 'Almuerzo completo',
        businessName: 'Comida del Corazón',
        location: 'Chapinero',
        imageEmoji: '🍲',
        expiryDate: now.add(Duration(days: 15)),
      ),
      Coupon(
        id: 'food_2',
        title: 'Tacos al Pastor x6',
        description: '6 tacos al pastor + guacamole',
        category: 'comida',
        costInCoins: 70,
        discount: 'Orden completa',
        businessName: 'Tacos Nocturnos',
        location: 'Usaquén',
        imageEmoji: '🌮',
        expiryDate: now.add(Duration(days: 22)),
      ),
      Coupon(
        id: 'food_3',
        title: 'Sushi Roll Premium',
        description: '8 piezas de sushi + edamame',
        category: 'comida',
        costInCoins: 140,
        discount: 'Combo premium',
        businessName: 'Sushi Express',
        location: 'La Candelaria',
        imageEmoji: '🍣',
        expiryDate: now.add(Duration(days: 18)),
      ),

      // Eventos
      Coupon(
        id: 'event_1',
        title: 'Entrada Cine',
        description: 'Entrada a película + palomitas',
        category: 'evento',
        costInCoins: 90,
        discount: 'Entrada + snack',
        businessName: 'Cine Cultural',
        location: 'Chapinero',
        imageEmoji: '🎬',
        expiryDate: now.add(Duration(days: 40)),
      ),
      Coupon(
        id: 'event_2',
        title: 'Clase Yoga',
        description: 'Clase de yoga + té relajante',
        category: 'evento',
        costInCoins: 55,
        discount: 'Clase completa',
        businessName: 'Yoga & Wellness',
        location: 'Usaquén',
        imageEmoji: '🧘',
        expiryDate: now.add(Duration(days: 32)),
      ),
      Coupon(
        id: 'event_3',
        title: 'Tour Histórico',
        description: 'Tour guiado por La Candelaria',
        category: 'evento',
        costInCoins: 110,
        discount: 'Tour completo',
        businessName: 'Bogotá Tours Local',
        location: 'La Candelaria',
        imageEmoji: '🚶',
        expiryDate: now.add(Duration(days: 45)),
      ),
    ];

    logger.i('✅ ${_availableCoupons.length} cupones inicializados');
  }

  // Obtener cupones disponibles sin redimir
  List<Coupon> getUnredeemedCoupons() {
    return _availableCoupons.where((c) => !c.isRedeemed && !c.isExpired).toList();
  }

  // Filtrar por categoría
  List<Coupon> getCouponsByCategory(String category) {
    return getUnredeemedCoupons()
        .where((c) => c.category == category)
        .toList();
  }

  // Obtener todas las categorías
  Set<String> getAllCategories() {
    return _availableCoupons.map((c) => c.category).toSet();
  }

  // Canjear un cupón (si el usuario tiene suficientes monedas)
  bool redeemCoupon(String couponId, int userCoins) {
    try {
      final coupon = _availableCoupons.firstWhere((c) => c.id == couponId);
      
      if (coupon.isRedeemed) {
        logger.w('⚠️ Cupón ya canjeado: $couponId');
        return false;
      }

      if (coupon.isExpired) {
        logger.w('⚠️ Cupón expirado: $couponId');
        return false;
      }

      if (userCoins < coupon.costInCoins) {
        logger.w('⚠️ Monedas insuficientes. Tienes: $userCoins, necesitas: ${coupon.costInCoins}');
        return false;
      }

      // Marcar como canjeado
      coupon.redeem();
      _redeemedCoupons.add(coupon);
      
      logger.i('✅ Cupón canjeado: ${coupon.title}');
      notifyListeners();
      
      return true;
    } catch (e) {
      logger.e('❌ Error canjeando cupón: $e');
      return false;
    }
  }

  // Obtener cupones canjeados
  List<Coupon> getRedeemedCoupons() {
    return _redeemedCoupons;
  }

  // Obtener resumen de categorías
  Map<String, int> getCategoryStats() {
    Map<String, int> stats = {};
    for (var coupon in getUnredeemedCoupons()) {
      stats[coupon.category] = (stats[coupon.category] ?? 0) + 1;
    }
    return stats;
  }
}
