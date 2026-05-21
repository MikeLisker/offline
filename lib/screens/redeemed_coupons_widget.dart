import 'package:flutter/material.dart';
import '../models/coupon.dart';

class RedeemedCouponsWidget extends StatelessWidget {
  final List<Coupon> redeemedCoupons;
  final VoidCallback onReset;
  final bool isDebugMode;

  const RedeemedCouponsWidget({
    super.key,
    required this.redeemedCoupons,
    required this.onReset,
    this.isDebugMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (redeemedCoupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎟️',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            const Text('Aún no has canjeado cupones'),
            const SizedBox(height: 32),
            if (isDebugMode)
              ElevatedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
                label: const Text('🔄 Restablecer Cupones (DEBUG)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: redeemedCoupons.length + (isDebugMode ? 1 : 0),
      itemBuilder: (context, index) {
        // Botón reset al final si está en debug
        if (isDebugMode && index == redeemedCoupons.length) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('🔄 Restablecer Todos (DEBUG)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          );
        }

        final coupon = redeemedCoupons[index];
        final isExpired = coupon.isRedeemedCouponExpired;
        final daysRemaining = coupon.daysRemainingAfterRedemption ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Column(
            children: [
              // Header con info básica
              Container(
                color: isExpired ? Colors.red.shade50 : Colors.blue.shade50,
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
                        border: Border.all(
                          color: isExpired ? Colors.red.shade200 : Colors.blue.shade200,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          coupon.imageEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coupon.businessName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Badge de vigencia
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.red.shade600
                                  : Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isExpired
                                  ? '❌ Vencido'
                                  : '✅ $daysRemaining días restantes',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Sección de código y QR
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Código del cupón
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Código del Cupón',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              // Copiar al portapapeles
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Text('📋 Código copiado: '),
                                      const Spacer(),
                                      Text(coupon.couponCode ?? 'N/A'),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Text(
                              coupon.couponCode ?? 'SIN CÓDIGO',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // QR simulado (representación visual)
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '█ █ █',
                              style: TextStyle(fontSize: 20, letterSpacing: 4),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '█ █ █',
                              style: TextStyle(fontSize: 20, letterSpacing: 4),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '█ █ █',
                              style: TextStyle(fontSize: 20, letterSpacing: 4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              coupon.couponCode?.substring(0, 5) ?? 'QR',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Detalles
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Canjeado el',
                            _formatDate(coupon.redeemedDate),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Vigencia hasta',
                            _formatDate(coupon.redemptionExpiryDate),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Ubicación',
                            coupon.location,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botón simular uso
                    ElevatedButton.icon(
                      onPressed: isExpired
                          ? null
                          : () {
                              _showSimulationDialog(context, coupon);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isExpired ? Colors.grey : Colors.green.shade600,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        isExpired
                            ? '❌ Cupón Vencido'
                            : '✅ Simular Uso del Cupón',
                        style: const TextStyle(color: Colors.white),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSimulationDialog(BuildContext context, Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Simulación de Uso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cupón: ${coupon.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    '🎉 ¡Cupón Utilizado Exitosamente!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${coupon.discount} en ${coupon.businessName}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Código: ${coupon.couponCode}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
