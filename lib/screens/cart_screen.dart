import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  String _appliedPromoCode = '';

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Widget _medicineImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      );
    }

    return Image.network(
      imagePath,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, _) {
        final CheckoutAmount checkoutAmount =
            provider.calculateCheckout(couponCode: _appliedPromoCode);

        if (provider.cartLines.isEmpty) {
          return const Center(
            child: Text(
              'Cart এখন খালি।',
              style: TextStyle(
                color: Color(0xFF385C88),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return Column(
          children: <Widget>[
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: provider.cartLines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final CartLine line = provider.cartLines[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE7EDF7)),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _medicineImage(line.medicine.imageUrl),
                      ),
                      title: Text(line.medicine.name),
                      subtitle: Text(
                        '৳ ${line.medicine.priceBdt.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              minimumSize: const Size(30, 30),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              provider.decreaseQuantity(line.medicine.id);
                            },
                            icon: const Icon(Icons.remove_rounded, size: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('${line.quantity}'),
                          ),
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              minimumSize: const Size(30, 30),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              provider.increaseQuantity(line.medicine.id);
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE8EEF8))),
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Promo code',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            final String code =
                                _promoController.text.trim().toUpperCase();
                            setState(() {
                              _appliedPromoCode = code;
                            });

                            final double discount = provider
                                .calculateCheckout(couponCode: code)
                                .discount;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  discount > 0
                                      ? 'Promo applied: ৳ ${discount.toStringAsFixed(2)} off'
                                      : 'Promo code invalid',
                                ),
                                duration: const Duration(milliseconds: 900),
                              ),
                            );
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _summaryRow(
                      label: 'Subtotal',
                      value: '৳ ${checkoutAmount.subtotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 4),
                    _summaryRow(
                      label: 'Delivery',
                      value: '৳ ${checkoutAmount.delivery.toStringAsFixed(2)}',
                    ),
                    if (checkoutAmount.discount > 0) ...<Widget>[
                      const SizedBox(height: 6),
                      _summaryRow(
                        label: 'Promo Discount',
                        value:
                            '-৳ ${checkoutAmount.discount.toStringAsFixed(2)}',
                        valueColor: const Color(0xFF0C8B61),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _summaryRow(
                      label: 'Total',
                      value: '৳ ${checkoutAmount.total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CheckoutScreen(
                                initialCouponCode: _appliedPromoCode,
                              ),
                            ),
                          );
                        },
                        child: const Text('Proceed to Checkout'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF355A88),
            fontSize: 15,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ??
                (isTotal ? const Color(0xFF0F5FC2) : const Color(0xFF3C608C)),
            fontSize: isTotal ? 22 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
