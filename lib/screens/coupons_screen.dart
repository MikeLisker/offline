import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coupon.dart';
import '../providers/coupon_provider.dart';
import '../providers/pet_provider.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'todos';

  @override
  void initState() {
    super.initState();
    final categories = context.read<CouponProvider>().getAllCategories();
    _tabController = TabController(length: categories.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final couponProvider = context.watch<CouponProvider>();
    
    final categories = couponProvider.getAllCategories().toList()..sort();
    final categoryEmojis = {
      'café': '☕',
      'tienda': '🛍️',
      'comida': '🍕',
      'evento': '🎭',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cupones & Recompensas'),
        elevation: 0,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                children: const [
                  Icon(Icons.all_inclusive),
                  SizedBox(width: 8),
                  Text('Todos'),
                ],
              ),
            ),
            ...categories.map((cat) => Tab(
              child: Row(
                children: [
                  Text(categoryEmojis[cat] ?? ''),
                  SizedBox(width: 8),
                  Text(
                    cat[0].toUpperCase() + cat.substring(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header con saldo de monedas
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu Saldo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        Text(
                          '${petProvider.pet.coins}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text('🪙', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Canjeados',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${couponProvider.getRedeemedCoupons().length}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // TabBarView con cupones
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab "Todos"
                _buildCouponList(
                  couponProvider.getUnredeemedCoupons(),
                  petProvider.pet.coins,
                  couponProvider,
                  petProvider,
                ),
                // Tabs por categoría
                ...categories.map((category) => _buildCouponList(
                  couponProvider.getCouponsByCategory(category),
                  petProvider.pet.coins,
                  couponProvider,
                  petProvider,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponList(
    List<Coupon> coupons,
    int userCoins,
    CouponProvider couponProvider,
    PetProvider petProvider,
  ) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '📭',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            const Text('No hay cupones disponibles en esta categoría'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        final canAfford = userCoins >= coupon.costInCoins;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Column(
            children: [
              // Header del cupón
              Container(
                color: Colors.green.shade50,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Center(
                        child: Text(
                          coupon.imageEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info del cupón
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coupon.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                coupon.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Detalles
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lugar de negocio
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            coupon.businessName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Descuento
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        coupon.discount,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Fecha de expiración
                    Text(
                      '⏰ Vence en ${coupon.daysUntilExpiry} días',
                      style: TextStyle(
                        fontSize: 11,
                        color: coupon.daysUntilExpiry <= 7
                            ? Colors.red
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de canje
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Costo en monedas
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: canAfford
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${coupon.costInCoins}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: canAfford
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '🪙',
                            style: TextStyle(
                              fontSize: 16,
                              color: canAfford
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón canjear
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canAfford
                            ? () {
                                _showRedeemDialog(
                                  context,
                                  coupon,
                                  couponProvider,
                                  petProvider,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Text(
                          canAfford ? 'Canjear' : 'Sin monedas',
                          style: TextStyle(
                            color: canAfford ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRedeemDialog(
    BuildContext context,
    Coupon coupon,
    CouponProvider couponProvider,
    PetProvider petProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Canje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Canjear ${coupon.title}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Costo:'),
                  Row(
                    children: [
                      Text(
                        '${coupon.costInCoins}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      const Text('🪙'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tu saldo después:'),
                  Row(
                    children: [
                      Text(
                        '${petProvider.pet.coins - coupon.costInCoins}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      const Text('🪙'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final success = couponProvider.redeemCoupon(
                coupon.id,
                petProvider.pet.coins,
              );

              if (success) {
                // Restar monedas del pet
                petProvider.pet.coins -= coupon.costInCoins;
                petProvider.notifyListeners();

                Navigator.pop(context);

                // Mostrar confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green.shade600,
                    content: Row(
                      children: [
                        const Text('✅ ¡Cupón canjeado exitosamente!'),
                        const Spacer(),
                        const Text('🎉'),
                      ],
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('❌ No se pudo canjear el cupón'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text('Canjear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
