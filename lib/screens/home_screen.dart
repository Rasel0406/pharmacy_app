import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/medicine.dart';
import '../providers/pharmacy_provider.dart';
import '../widgets/medicine_card.dart';
import 'medicine_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loadedOnce = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) {
      return;
    }

    _loadedOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<PharmacyProvider>().loadMedicines();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final PharmacyProvider provider = context.read<PharmacyProvider>();
    if (!_scrollController.hasClients || !provider.hasMoreMedicines) {
      return;
    }

    final double threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels >= threshold) {
      provider.loadMoreMedicines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return _buildShimmerGrid();
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A1E1E),
                ),
              ),
            ),
          );
        }

        final List<Medicine> suggestions = provider.searchSuggestions;

        return SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: provider.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: 'Search medicine by name or generic',
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFD5E3F6)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFD5E3F6)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0F5FC2),
                                  width: 1.3,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Filter',
                          onPressed: () => _openFilterSheet(context, provider),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    if (provider.searchQuery.trim().isNotEmpty &&
                        suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCE8F9)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final Medicine item = suggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(item.name),
                              subtitle: Text(item.genericName),
                              onTap: () {
                                _searchController.text = item.name;
                                provider.setSearchQuery(item.name);
                                FocusScope.of(context).unfocus();
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final String category = provider.categories[index];
                    final bool selected = category == provider.selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) => provider.setCategory(category),
                        selectedColor: const Color(0xFF0F5FC2),
                        labelStyle: TextStyle(
                          color:
                              selected ? Colors.white : const Color(0xFF31527C),
                          fontWeight: FontWeight.w600,
                        ),
                        side: const BorderSide(color: Color(0xFFD9E4F5)),
                        backgroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: provider.featuredMedicines.isEmpty
                    ? const Center(
                        child: Text(
                          'No medicines found for this filter',
                          style: TextStyle(
                            color: Color(0xFF45658F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: provider.featuredMedicines.length +
                            (provider.hasMoreMedicines ? 1 : 0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width >= 900 ? 4 : 2,
                          childAspectRatio: 0.56,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          if (index >= provider.featuredMedicines.length) {
                            return _buildPaginationShimmerTile();
                          }

                          final Medicine medicine =
                              provider.featuredMedicines[index];
                          return MedicineCard(
                            medicine: medicine,
                            isFavorite: provider.isFavorite(medicine.id),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => MedicineDetailScreen(
                                    medicine: medicine,
                                  ),
                                ),
                              );
                            },
                            onAdd: () {
                              provider.addToCart(medicine);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(milliseconds: 1000),
                                  content:
                                      Text('${medicine.name} cart-এ যোগ হয়েছে'),
                                ),
                              );
                            },
                            onToggleFavorite: () async {
                              await provider.toggleWishlist(medicine.id);
                              if (!context.mounted) {
                                return;
                              }

                              final bool nowFavorite =
                                  provider.isFavorite(medicine.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(milliseconds: 900),
                                  content: Text(
                                    nowFavorite
                                        ? '${medicine.name} wishlist-এ যোগ হয়েছে'
                                        : '${medicine.name} wishlist থেকে সরানো হয়েছে',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    PharmacyProvider provider,
  ) async {
    final List<String> localManufacturers =
        List<String>.from(provider.manufacturers);
    final Set<String> localSelectedManufacturers =
        provider.selectedManufacturers.toSet();
    bool localInStockOnly = provider.inStockOnly;
    String localSortBy = provider.sortBy;
    double localMin = provider.selectedMinPrice;
    double localMax = provider.selectedMaxPrice;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF173E6C),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Price Range: ৳${localMin.toStringAsFixed(0)} - ৳${localMax.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF355A88),
                        ),
                      ),
                      RangeSlider(
                        values: RangeValues(localMin, localMax),
                        min: provider.minAvailablePrice,
                        max: provider.maxAvailablePrice,
                        divisions: 20,
                        labels: RangeLabels(
                          localMin.toStringAsFixed(0),
                          localMax.toStringAsFixed(0),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            localMin = value.start;
                            localMax = value.end;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manufacturer',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF355A88),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: localManufacturers
                            .map(
                              (name) => FilterChip(
                                label: Text(name),
                                selected:
                                    localSelectedManufacturers.contains(name),
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      localSelectedManufacturers.add(name);
                                    } else {
                                      localSelectedManufacturers.remove(name);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: localInStockOnly,
                        title: const Text('In stock only'),
                        onChanged: (value) {
                          setModalState(() => localInStockOnly = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: localSortBy,
                        decoration: const InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(),
                        ),
                        items: provider.sortOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() => localSortBy = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                provider.resetFilters();
                                Navigator.of(sheetContext).pop();
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                provider.setPriceRange(
                                    min: localMin, max: localMax);
                                provider.setInStockOnly(localInStockOnly);
                                provider.setSortBy(localSortBy);

                                final Set<String> existing =
                                    provider.selectedManufacturers.toSet();
                                for (final String manufacturer in existing) {
                                  if (!localSelectedManufacturers
                                      .contains(manufacturer)) {
                                    provider.toggleManufacturer(manufacturer);
                                  }
                                }
                                for (final String manufacturer
                                    in localSelectedManufacturers) {
                                  if (!existing.contains(manufacturer)) {
                                    provider.toggleManufacturer(manufacturer);
                                  }
                                }

                                Navigator.of(sheetContext).pop();
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.56,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE6EEF8),
          highlightColor: const Color(0xFFF4F8FF),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationShimmerTile() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6EEF8),
      highlightColor: const Color(0xFFF4F8FF),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
