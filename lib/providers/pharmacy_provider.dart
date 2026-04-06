import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medicine.dart';
import '../services/pharmacy_api_service.dart';

class PharmacyProvider extends ChangeNotifier {
  PharmacyProvider({PharmacyApiService? apiService})
      : _apiService = apiService ?? PharmacyApiService();

  static const List<String> orderStatusFlow = <String>[
    'Confirmed',
    'Packed',
    'Picked Up',
    'On The Way',
    'Delivered',
  ];

  final PharmacyApiService _apiService;
  List<Medicine> _medicines = <Medicine>[];
  List<String> _categories = <String>[];
  final Map<int, int> _cart = <int, int>{};
  final Set<int> _wishlist = <int>{};
  final List<OrderReceipt> _orders = <OrderReceipt>[];
  List<SavedAddress> _savedAddresses = <SavedAddress>[];

  final int _pageSize = 20;
  int _visibleCount = 20;
  double? _selectedMinPrice;
  double? _selectedMaxPrice;
  final Set<String> _selectedManufacturers = <String>{};
  bool _inStockOnly = false;
  String _sortBy = 'Name A-Z';

  bool _isLoading = false;
  String? _errorMessage;
  String? _lastOrderSyncError;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  String _fullName = 'Guest User';
  String _phone = '';
  String _email = '';
  String _address = '';
  bool _notificationsEnabled = true;

  static const String _wishlistKey = 'wishlist_ids';
  static const String _ordersKey = 'order_history';
  static const String _nameKey = 'profile_name';
  static const String _phoneKey = 'profile_phone';
  static const String _emailKey = 'profile_email';
  static const String _addressKey = 'profile_address';
  static const String _notificationsKey = 'profile_notifications';
  static const String _savedAddressesKey = 'saved_addresses';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastOrderSyncError => _lastOrderSyncError;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get fullName => _fullName;
  String get phone => _phone;
  String get email => _email;
  String get address => _address;
  bool get notificationsEnabled => _notificationsEnabled;
  List<SavedAddress> get savedAddresses =>
      List<SavedAddress>.unmodifiable(_savedAddresses);
  bool get inStockOnly => _inStockOnly;
  String get sortBy => _sortBy;
  double get minAvailablePrice {
    if (_medicines.isEmpty) {
      return 0;
    }
    return _medicines
        .map((m) => m.priceBdt)
        .reduce((value, element) => value < element ? value : element);
  }

  double get maxAvailablePrice {
    if (_medicines.isEmpty) {
      return 0;
    }
    return _medicines
        .map((m) => m.priceBdt)
        .reduce((value, element) => value > element ? value : element);
  }

  double get selectedMinPrice => _selectedMinPrice ?? minAvailablePrice;
  double get selectedMaxPrice => _selectedMaxPrice ?? maxAvailablePrice;
  List<String> get selectedManufacturers =>
      List<String>.unmodifiable(_selectedManufacturers);
  List<String> get manufacturers {
    final Set<String> names = _medicines.map((m) => m.manufacturer).toSet();
    final List<String> sorted = names.toList()..sort();
    return sorted;
  }

  List<String> get sortOptions => const <String>[
        'Name A-Z',
        'Price Low-High',
        'Price High-Low',
        'New Arrivals'
      ];

  List<Medicine> get medicines => List<Medicine>.unmodifiable(_medicines);
  List<OrderReceipt> get orders => List<OrderReceipt>.unmodifiable(_orders);

  int get wishlistCount => _wishlist.length;

  List<Medicine> get wishlistMedicines {
    return _medicines.where((m) => _wishlist.contains(m.id)).toList();
  }

  List<String> get categories {
    if (_categories.isNotEmpty) {
      return <String>['All', ..._categories];
    }

    final Set<String> unique = _medicines.map((m) => m.category).toSet();
    final List<String> sorted = unique.toList()..sort();
    return <String>['All', ...sorted];
  }

  List<Medicine> get filteredMedicines {
    final List<Medicine> base = _medicines.where((medicine) {
      final bool matchesCategory =
          _selectedCategory == 'All' || medicine.category == _selectedCategory;

      final String query = _searchQuery.trim().toLowerCase();
      final bool matchesQuery = query.isEmpty ||
          medicine.name.toLowerCase().contains(query) ||
          medicine.genericName.toLowerCase().contains(query);

      final bool matchesPrice = medicine.priceBdt >= selectedMinPrice &&
          medicine.priceBdt <= selectedMaxPrice;
      final bool matchesManufacturer = _selectedManufacturers.isEmpty ||
          _selectedManufacturers.contains(medicine.manufacturer);
      final bool matchesStock =
          !_inStockOnly || _isMedicineInStock(medicine.id);

      return matchesCategory &&
          matchesQuery &&
          matchesPrice &&
          matchesManufacturer &&
          matchesStock;
    }).toList();

    if (_sortBy == 'Price Low-High') {
      base.sort((a, b) => a.priceBdt.compareTo(b.priceBdt));
    } else if (_sortBy == 'Price High-Low') {
      base.sort((a, b) => b.priceBdt.compareTo(a.priceBdt));
    } else if (_sortBy == 'New Arrivals') {
      base.sort((a, b) => b.id.compareTo(a.id));
    } else {
      base.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return base;
  }

  List<Medicine> get featuredMedicines {
    final List<Medicine> source = filteredMedicines;
    final int end =
        _visibleCount > source.length ? source.length : _visibleCount;
    return source.take(end).toList();
  }

  bool get hasMoreMedicines => _visibleCount < filteredMedicines.length;

  SavedAddress? get defaultAddress {
    for (final SavedAddress address in _savedAddresses) {
      if (address.isDefault) {
        return address;
      }
    }
    return _savedAddresses.isEmpty ? null : _savedAddresses.first;
  }

  List<Medicine> get searchSuggestions {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return <Medicine>[];
    }

    final List<Medicine> list = _medicines.where((medicine) {
      return medicine.name.toLowerCase().contains(query) ||
          medicine.genericName.toLowerCase().contains(query);
    }).toList();

    return list.take(6).toList();
  }

  int get cartCount {
    return _cart.values.fold<int>(0, (sum, quantity) => sum + quantity);
  }

  List<CartLine> get cartLines {
    final List<CartLine> lines = <CartLine>[];
    for (final entry in _cart.entries) {
      final Medicine medicine =
          _medicines.firstWhere((item) => item.id == entry.key);
      lines.add(CartLine(medicine: medicine, quantity: entry.value));
    }
    return lines;
  }

  double get cartTotal {
    return cartLines.fold<double>(
      0,
      (sum, line) => sum + (line.medicine.priceBdt * line.quantity),
    );
  }

  double get deliveryFee => cartLines.isEmpty ? 0 : 40;

  double get grandTotal => cartTotal + deliveryFee;

  CheckoutAmount calculateCheckout({String couponCode = ''}) {
    final String normalizedCode = couponCode.trim().toUpperCase();
    final double subtotal = cartTotal;
    final double delivery = deliveryFee;
    final double discount = _calculateDiscount(
      couponCode: normalizedCode,
      subtotal: subtotal,
    );
    final double total =
        (subtotal + delivery - discount).clamp(0, double.infinity);

    return CheckoutAmount(
      subtotal: subtotal,
      delivery: delivery,
      discount: discount,
      total: total,
      couponCode: normalizedCode,
    );
  }

  Future<void> loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _wishlist
      ..clear()
      ..addAll(
        prefs
                .getStringList(_wishlistKey)
                ?.map((e) => int.tryParse(e))
                .whereType<int>()
                .toList() ??
            <int>[],
      );

    _fullName = prefs.getString(_nameKey) ?? 'Guest User';
    _phone = prefs.getString(_phoneKey) ?? '';
    _email = prefs.getString(_emailKey) ?? '';
    _address = prefs.getString(_addressKey) ?? '';
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;

    final String? rawAddresses = prefs.getString(_savedAddressesKey);
    _savedAddresses = _decodeAddresses(rawAddresses);
    if (_savedAddresses.isEmpty && _address.trim().isNotEmpty) {
      _savedAddresses = <SavedAddress>[
        SavedAddress(
          id: 'addr-default',
          label: 'Home',
          address: _address,
          isDefault: true,
        ),
      ];
    }

    final String? rawOrders = prefs.getString(_ordersKey);
    _orders
      ..clear()
      ..addAll(_decodeOrders(rawOrders));
    notifyListeners();
  }

  Future<void> loadMedicines() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Medicine> loadedMedicines = await _apiService.fetchMedicines();
      final List<String> loadedCategories = await _apiService.fetchCategories(
        fallbackMedicines: loadedMedicines,
      );

      _medicines = loadedMedicines;
      _categories = loadedCategories;

      _selectedMinPrice ??= minAvailablePrice;
      _selectedMaxPrice ??= maxAvailablePrice;
      _resetPagination();

      if (_selectedCategory != 'All' &&
          !_categories.contains(_selectedCategory)) {
        _selectedCategory = 'All';
      }
    } catch (_) {
      _errorMessage = 'Medicine data load করা যায়নি।';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _resetPagination();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _resetPagination();
    notifyListeners();
  }

  void setSortBy(String value) {
    _sortBy = value;
    _resetPagination();
    notifyListeners();
  }

  void setInStockOnly(bool value) {
    _inStockOnly = value;
    _resetPagination();
    notifyListeners();
  }

  void setPriceRange({required double min, required double max}) {
    _selectedMinPrice = min;
    _selectedMaxPrice = max;
    _resetPagination();
    notifyListeners();
  }

  void toggleManufacturer(String manufacturer) {
    if (_selectedManufacturers.contains(manufacturer)) {
      _selectedManufacturers.remove(manufacturer);
    } else {
      _selectedManufacturers.add(manufacturer);
    }
    _resetPagination();
    notifyListeners();
  }

  void resetFilters() {
    _selectedMinPrice = minAvailablePrice;
    _selectedMaxPrice = maxAvailablePrice;
    _selectedManufacturers.clear();
    _inStockOnly = false;
    _sortBy = 'Name A-Z';
    _resetPagination();
    notifyListeners();
  }

  void loadMoreMedicines() {
    if (!hasMoreMedicines) {
      return;
    }

    _visibleCount += _pageSize;
    notifyListeners();
  }

  bool isFavorite(int medicineId) {
    return _wishlist.contains(medicineId);
  }

  Future<void> toggleWishlist(int medicineId) async {
    if (_wishlist.contains(medicineId)) {
      _wishlist.remove(medicineId);
    } else {
      _wishlist.add(medicineId);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _wishlistKey,
      _wishlist.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }

  Future<void> saveProfile({
    required String fullName,
    required String phone,
    required String email,
    required String address,
    required bool notificationsEnabled,
  }) async {
    _fullName = fullName.trim();
    _phone = phone.trim();
    _email = email.trim();
    _address = address.trim();
    _notificationsEnabled = notificationsEnabled;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, _fullName);
    await prefs.setString(_phoneKey, _phone);
    await prefs.setString(_emailKey, _email);
    await prefs.setString(_addressKey, _address);
    await prefs.setBool(_notificationsKey, _notificationsEnabled);

    if (_address.isNotEmpty && _savedAddresses.isEmpty) {
      _savedAddresses = <SavedAddress>[
        SavedAddress(
          id: 'addr-default',
          label: 'Home',
          address: _address,
          isDefault: true,
        ),
      ];
      await _persistAddresses();
    }
    notifyListeners();
  }

  Future<void> addSavedAddress({
    required String label,
    required String address,
    bool setAsDefault = false,
  }) async {
    final SavedAddress newAddress = SavedAddress(
      id: 'addr-${DateTime.now().microsecondsSinceEpoch}',
      label: label.trim().isEmpty ? 'Address' : label.trim(),
      address: address.trim(),
      isDefault: setAsDefault || _savedAddresses.isEmpty,
    );

    if (newAddress.isDefault) {
      _savedAddresses = _savedAddresses
          .map((item) => item.copyWith(isDefault: false))
          .toList();
    }

    _savedAddresses = <SavedAddress>[..._savedAddresses, newAddress];
    _syncDefaultAddressToProfile();
    await _persistAddresses();
    notifyListeners();
  }

  Future<void> updateSavedAddress({
    required String id,
    required String label,
    required String address,
    required bool setAsDefault,
  }) async {
    _savedAddresses = _savedAddresses.map((item) {
      if (item.id == id) {
        return item.copyWith(
          label: label.trim().isEmpty ? item.label : label.trim(),
          address: address.trim(),
          isDefault: setAsDefault,
        );
      }

      return setAsDefault ? item.copyWith(isDefault: false) : item;
    }).toList();

    _ensureSingleDefaultAddress();
    _syncDefaultAddressToProfile();
    await _persistAddresses();
    notifyListeners();
  }

  Future<void> deleteSavedAddress(String id) async {
    _savedAddresses = _savedAddresses.where((item) => item.id != id).toList();
    _ensureSingleDefaultAddress();
    _syncDefaultAddressToProfile();
    await _persistAddresses();
    notifyListeners();
  }

  Future<void> setDefaultAddress(String id) async {
    _savedAddresses = _savedAddresses
        .map((item) => item.copyWith(isDefault: item.id == id))
        .toList();
    _syncDefaultAddressToProfile();
    await _persistAddresses();
    notifyListeners();
  }

  void addToCart(Medicine medicine) {
    _cart.update(medicine.id, (old) => old + 1, ifAbsent: () => 1);
    notifyListeners();
  }

  void increaseQuantity(int medicineId) {
    _cart.update(medicineId, (old) => old + 1, ifAbsent: () => 1);
    notifyListeners();
  }

  void decreaseQuantity(int medicineId) {
    final int current = _cart[medicineId] ?? 0;
    if (current == 0) {
      return;
    }

    if (current <= 1) {
      _cart.remove(medicineId);
    } else {
      _cart[medicineId] = current - 1;
    }
    notifyListeners();
  }

  void removeFromCart(int medicineId) {
    _cart.remove(medicineId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<OrderReceipt> placeOrder({
    required String customerName,
    required String phone,
    required String deliveryAddress,
    required String paymentMethod,
    required String paymentDetails,
    required String couponCode,
    required double discount,
    required String note,
  }) async {
    final List<CartLine> lines = cartLines;
    final List<OrderLineItem> orderItems = lines
        .map(
          (line) => OrderLineItem(
            medicineId: line.medicine.id,
            medicineName: line.medicine.name,
            unitPrice: line.medicine.priceBdt,
            quantity: line.quantity,
          ),
        )
        .toList();

    final double subtotal = cartTotal;
    final double delivery = deliveryFee;
    final double total =
        (subtotal + delivery - discount).clamp(0, double.infinity);

    final OrderReceipt receipt = OrderReceipt(
      orderId: 'LP-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: delivery,
      discount: discount,
      total: total,
      customerName: customerName,
      phone: phone,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      paymentDetails: paymentDetails,
      couponCode: couponCode,
      note: note,
      statusIndex: 0,
      isCanceled: false,
    );

    _orders.insert(0, receipt);
    _cart.clear();
    _lastOrderSyncError = null;
    await _persistOrders();
    await _saveOrderToFirestore(receipt);
    notifyListeners();
    return receipt;
  }

  Future<void> advanceOrderStatus(String orderId) async {
    bool changed = false;
    _orders.replaceRange(
        0,
        _orders.length,
        _orders.map((order) {
          if (order.orderId != orderId || order.isCanceled) {
            return order;
          }

          changed = true;
          final int next = (order.statusIndex + 1)
              .clamp(0, PharmacyProvider.orderStatusFlow.length - 1);
          return order.copyWith(statusIndex: next);
        }).toList());

    if (!changed) {
      return;
    }

    await _persistOrders();
    notifyListeners();
  }

  Future<void> cancelOrder(String orderId) async {
    bool changed = false;
    _orders.replaceRange(
        0,
        _orders.length,
        _orders.map((order) {
          if (order.orderId != orderId ||
              order.isCanceled ||
              order.statusIndex >=
                  PharmacyProvider.orderStatusFlow.length - 1) {
            return order;
          }

          changed = true;
          return order.copyWith(isCanceled: true);
        }).toList());

    if (!changed) {
      return;
    }

    await _persistOrders();
    notifyListeners();
  }

  String getOrderStatusLabel(OrderReceipt order) {
    if (order.isCanceled) {
      return 'Canceled';
    }

    return PharmacyProvider.orderStatusFlow[order.statusIndex
        .clamp(0, PharmacyProvider.orderStatusFlow.length - 1)];
  }

  List<OrderReceipt> filterOrders({
    String query = '',
    String paymentMethod = 'All',
    String sortBy = 'Newest',
    String dateFilter = 'All Time',
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final String normalizedQuery = query.trim().toLowerCase();

    List<OrderReceipt> result = _orders.where((order) {
      final bool methodMatch =
          paymentMethod == 'All' || order.paymentMethod == paymentMethod;
      final bool dateMatch = _matchesDateRange(
        orderDate: order.createdAt,
        dateFilter: dateFilter,
        customFrom: customFrom,
        customTo: customTo,
      );

      final bool queryMatch = normalizedQuery.isEmpty ||
          order.orderId.toLowerCase().contains(normalizedQuery) ||
          order.customerName.toLowerCase().contains(normalizedQuery) ||
          order.items.any(
            (item) => item.medicineName.toLowerCase().contains(normalizedQuery),
          );

      return methodMatch && dateMatch && queryMatch;
    }).toList();

    if (sortBy == 'Highest Total') {
      result.sort((a, b) => b.total.compareTo(a.total));
    } else if (sortBy == 'Oldest') {
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  bool _matchesDateRange({
    required DateTime orderDate,
    required String dateFilter,
    required DateTime? customFrom,
    required DateTime? customTo,
  }) {
    final DateTime now = DateTime.now();
    final DateTime orderDay =
        DateTime(orderDate.year, orderDate.month, orderDate.day);

    if (dateFilter == 'Today') {
      final DateTime today = DateTime(now.year, now.month, now.day);
      return orderDay == today;
    }

    if (dateFilter == 'Last 7 Days') {
      final DateTime from = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      return !orderDay.isBefore(from);
    }

    if (dateFilter == 'Last 30 Days') {
      final DateTime from = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 29));
      return !orderDay.isBefore(from);
    }

    if (dateFilter == 'Custom') {
      if (customFrom == null || customTo == null) {
        return true;
      }
      final DateTime fromDay =
          DateTime(customFrom.year, customFrom.month, customFrom.day);
      final DateTime toDay =
          DateTime(customTo.year, customTo.month, customTo.day);
      return !orderDay.isBefore(fromDay) && !orderDay.isAfter(toDay);
    }

    return true;
  }

  void reorder(OrderReceipt order) {
    for (final OrderLineItem item in order.items) {
      final Medicine? medicine = _findMedicineById(item.medicineId);
      if (medicine == null) {
        continue;
      }

      _cart.update(
        item.medicineId,
        (old) => old + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }
    notifyListeners();
  }

  Medicine? _findMedicineById(int id) {
    for (final Medicine medicine in _medicines) {
      if (medicine.id == id) {
        return medicine;
      }
    }
    return null;
  }

  OrderReceipt? getOrderById(String orderId) {
    for (final OrderReceipt order in _orders) {
      if (order.orderId == orderId) {
        return order;
      }
    }
    return null;
  }

  double _calculateDiscount({
    required String couponCode,
    required double subtotal,
  }) {
    if (couponCode.isEmpty) {
      return 0;
    }

    switch (couponCode) {
      case 'SAVE10':
        return subtotal * 0.10;
      case 'HEALTH5':
        return subtotal >= 500 ? 50 : 0;
      case 'FIRST20':
        return subtotal * 0.20;
      default:
        return 0;
    }
  }

  Future<void> _persistOrders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _orders.map((order) => order.toJson()).toList(),
    );
    await prefs.setString(_ordersKey, encoded);
  }

  Future<void> _saveOrderToFirestore(OrderReceipt order) async {
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        ...order.toJson(),
        'status_label': getOrderStatusLabel(order),
        'created_at_server': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(payload);
      _lastOrderSyncError = null;
    } on FirebaseException catch (error) {
      _lastOrderSyncError =
          'Firestore sync failed (${error.code}): ${error.message ?? 'Unknown error'}';
      debugPrint('Order sync failed: ${error.code} ${error.message}');
    } catch (error) {
      _lastOrderSyncError = 'Firestore sync failed: $error';
      debugPrint('Order sync failed: $error');
    }
  }

  Future<void> _persistAddresses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _savedAddresses.map((address) => address.toJson()).toList(),
    );
    await prefs.setString(_savedAddressesKey, encoded);
    await prefs.setString(_addressKey, _address);
  }

  List<OrderReceipt> _decodeOrders(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <OrderReceipt>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => OrderReceipt.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <OrderReceipt>[];
    }
  }

  List<SavedAddress> _decodeAddresses(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <SavedAddress>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => SavedAddress.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <SavedAddress>[];
    }
  }

  void _ensureSingleDefaultAddress() {
    if (_savedAddresses.isEmpty) {
      return;
    }

    final bool hasDefault = _savedAddresses.any((item) => item.isDefault);
    if (hasDefault) {
      return;
    }

    _savedAddresses = <SavedAddress>[
      _savedAddresses.first.copyWith(isDefault: true),
      ..._savedAddresses.skip(1),
    ];
  }

  void _syncDefaultAddressToProfile() {
    final SavedAddress? selected = defaultAddress;
    _address = selected?.address ?? _address;
  }

  void _resetPagination() {
    _visibleCount = _pageSize;
  }

  bool _isMedicineInStock(int id) {
    return id % 7 != 0;
  }
}

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String address;
  final bool isDefault;

  SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    bool? isDefault,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'address': address,
      'is_default': isDefault,
    };
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? 'Address',
      address: (json['address'] as String?) ?? '',
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }
}

class CartLine {
  const CartLine({required this.medicine, required this.quantity});

  final Medicine medicine;
  final int quantity;
}

class OrderReceipt {
  const OrderReceipt({
    required this.orderId,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.customerName,
    required this.phone,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentDetails,
    required this.couponCode,
    required this.note,
    required this.statusIndex,
    required this.isCanceled,
  });

  final String orderId;
  final DateTime createdAt;
  final List<OrderLineItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String customerName;
  final String phone;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentDetails;
  final String couponCode;
  final String note;
  final int statusIndex;
  final bool isCanceled;

  OrderReceipt copyWith({
    int? statusIndex,
    bool? isCanceled,
  }) {
    return OrderReceipt(
      orderId: orderId,
      createdAt: createdAt,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      customerName: customerName,
      phone: phone,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      paymentDetails: paymentDetails,
      couponCode: couponCode,
      note: note,
      statusIndex: statusIndex ?? this.statusIndex,
      isCanceled: isCanceled ?? this.isCanceled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'order_id': orderId,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'total': total,
      'customer_name': customerName,
      'phone': phone,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      'payment_details': paymentDetails,
      'coupon_code': couponCode,
      'note': note,
      'status_index': statusIndex,
      'is_canceled': isCanceled,
    };
  }

  factory OrderReceipt.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson =
        json['items'] as List<dynamic>? ?? <dynamic>[];

    return OrderReceipt(
      orderId: json['order_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: itemsJson
          .map((item) => OrderLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      customerName: json['customer_name'] as String,
      phone: json['phone'] as String,
      deliveryAddress: json['delivery_address'] as String,
      paymentMethod: json['payment_method'] as String,
      paymentDetails: (json['payment_details'] as String?) ?? '',
      couponCode: (json['coupon_code'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
      statusIndex: (json['status_index'] as int?) ?? 0,
      isCanceled: (json['is_canceled'] as bool?) ?? false,
    );
  }
}

class OrderLineItem {
  const OrderLineItem({
    required this.medicineId,
    required this.medicineName,
    required this.unitPrice,
    required this.quantity,
  });

  final int medicineId;
  final String medicineName;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'unit_price': unitPrice,
      'quantity': quantity,
    };
  }

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      medicineId: json['medicine_id'] as int,
      medicineName: json['medicine_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}

class CheckoutAmount {
  const CheckoutAmount({
    required this.subtotal,
    required this.delivery,
    required this.discount,
    required this.total,
    required this.couponCode,
  });

  final double subtotal;
  final double delivery;
  final double discount;
  final double total;
  final String couponCode;
}
