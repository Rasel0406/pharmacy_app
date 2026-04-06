import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../providers/pharmacy_provider.dart';

class MedicineDetailScreen extends StatelessWidget {
  const MedicineDetailScreen({super.key, required this.medicine});

  final Medicine medicine;

  Widget _medicineImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          height: 240,
          child: Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      );
    }

    return Image.network(
      imagePath,
      width: double.infinity,
      height: 240,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (_, __, ___) => const SizedBox(
        height: 240,
        child: Center(child: Icon(Icons.image_not_supported_outlined)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PharmacyProvider provider = context.watch<PharmacyProvider>();
    final bool isFavorite = provider.isFavorite(medicine.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(medicine.name),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await provider.toggleWishlist(medicine.id);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    provider.isFavorite(medicine.id)
                        ? '${medicine.name} wishlist-এ যোগ হয়েছে'
                        : '${medicine.name} wishlist থেকে সরানো হয়েছে',
                  ),
                ),
              );
            },
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFE74E68) : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _medicineImage(medicine.imageUrl),
            ),
            const SizedBox(height: 16),
            Text(
              medicine.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E305A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Generic: ${medicine.genericName}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF3F5E83)),
            ),
            const SizedBox(height: 12),
            _infoTile('Category', medicine.category),
            _infoTile('Manufacturer', medicine.manufacturer),
            _infoTile(
                'Dosage', '${medicine.dosageForm} (${medicine.strength})'),
            _infoTile('Uses', medicine.uses),
            _infoTile('Details', medicine.description),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Text(
                  '৳ ${medicine.priceBdt.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F5FC2),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 180,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<PharmacyProvider>().addToCart(medicine);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('${medicine.name} cart-এ যোগ হয়েছে')),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                    label: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A3A63)),
              children: <TextSpan>[
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
