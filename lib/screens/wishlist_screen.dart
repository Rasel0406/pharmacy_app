import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../providers/pharmacy_provider.dart';
import 'medicine_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _category = 'All';
  String _sortBy = 'Name A-Z';

  Widget _medicineImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      );
    }

    return Image.network(
      imagePath,
      width: 58,
      height: 58,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, _) {
        final List<Medicine> wishlist = _buildFilteredWishlist(provider);

        final Set<String> categoriesSet =
            provider.wishlistMedicines.map((m) => m.category).toSet();
        final List<String> categories = <String>[
          'All',
          ...categoriesSet.toList()..sort(),
        ];

        if (!categories.contains(_category)) {
          _category = 'All';
        }

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search wishlist medicines',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDCE8F9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDCE8F9)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _category = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sort',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const <String>[
                        'Name A-Z',
                        'Price Low-High',
                        'Price High-Low',
                      ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _sortBy = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: wishlist.isEmpty
                  ? const Center(
                      child: Text(
                        'No wishlist items for current search/filter.',
                        style: TextStyle(
                          color: Color(0xFF45658F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: wishlist.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final Medicine medicine = wishlist[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    MedicineDetailScreen(medicine: medicine),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFDDE8F9)),
                            ),
                            child: Row(
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _medicineImage(medicine.imageUrl),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        medicine.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF183F6D),
                                        ),
                                      ),
                                      Text(
                                        medicine.genericName,
                                        style: const TextStyle(
                                          color: Color(0xFF52739E),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '৳ ${medicine.priceBdt.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF0F5FC2),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: <Widget>[
                                    IconButton(
                                      onPressed: () {
                                        provider.addToCart(medicine);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${medicine.name} cart-এ যোগ হয়েছে',
                                            ),
                                            duration: const Duration(
                                                milliseconds: 900),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.add_shopping_cart_rounded,
                                        color: Color(0xFF0F5FC2),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        await provider
                                            .toggleWishlist(medicine.id);
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFE44B67),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<Medicine> _buildFilteredWishlist(PharmacyProvider provider) {
    final String query = _searchController.text.trim().toLowerCase();

    List<Medicine> result = provider.wishlistMedicines.where((medicine) {
      final bool categoryMatch =
          _category == 'All' || medicine.category == _category;
      final bool queryMatch = query.isEmpty ||
          medicine.name.toLowerCase().contains(query) ||
          medicine.genericName.toLowerCase().contains(query);
      return categoryMatch && queryMatch;
    }).toList();

    if (_sortBy == 'Price Low-High') {
      result.sort((a, b) => a.priceBdt.compareTo(b.priceBdt));
    } else if (_sortBy == 'Price High-Low') {
      result.sort((a, b) => b.priceBdt.compareTo(a.priceBdt));
    } else {
      result
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return result;
  }
}
