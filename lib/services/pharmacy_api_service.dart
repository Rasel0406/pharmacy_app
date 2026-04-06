import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/medicine.dart';

class PharmacyApiService {
  PharmacyApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl =
            (baseUrl ?? const String.fromEnvironment('API_BASE_URL')).trim();

  final http.Client _client;
  final String _baseUrl;

  Future<List<Medicine>> fetchMedicines() async {
    final List<Medicine>? firestoreMedicines =
        await _fetchMedicinesFromFirestore();
    if (firestoreMedicines != null && firestoreMedicines.isNotEmpty) {
      return firestoreMedicines;
    }

    final List<Medicine>? apiMedicines = await _fetchMedicinesFromApi();
    if (apiMedicines != null && apiMedicines.isNotEmpty) {
      return apiMedicines;
    }

    return _fetchMedicinesFromLocalJson();
  }

  Future<List<String>> fetchCategories({
    List<Medicine>? fallbackMedicines,
  }) async {
    final List<Medicine>? firestoreMedicines =
        await _fetchMedicinesFromFirestore();
    if (firestoreMedicines != null && firestoreMedicines.isNotEmpty) {
      final List<String> firestoreCategories =
          firestoreMedicines.map((m) => m.category).toList(growable: false);
      return _normalizeCategories(firestoreCategories);
    }

    final List<String>? apiCategories = await _fetchCategoriesFromApi();
    if (apiCategories != null && apiCategories.isNotEmpty) {
      return _normalizeCategories(apiCategories);
    }

    final List<Medicine> sourceMedicines =
        fallbackMedicines ?? await _fetchMedicinesFromLocalJson();
    final List<String> categories =
        sourceMedicines.map((m) => m.category).toList(growable: false);
    return _normalizeCategories(categories);
  }

  Future<List<Medicine>?> _fetchMedicinesFromFirestore() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('medicines').get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final List<Medicine> medicines = <Medicine>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> raw = doc.data();
        final int? id = _parseMedicineId(raw['id']) ?? int.tryParse(doc.id);
        if (id == null) {
          continue;
        }

        final Map<String, dynamic> normalized = <String, dynamic>{
          'id': id,
          'name': _pickString(raw, <String>['name']) ?? '',
          'generic_name':
              _pickString(raw, <String>['generic_name', 'genericName']) ?? '',
          'manufacturer': _pickString(raw, <String>['manufacturer']) ?? '',
          'category': _pickString(raw, <String>['category']) ?? '',
          'price_bdt':
              _pickNum(raw, <String>['price_bdt', 'priceBdt', 'price']) ?? 0,
          'dosage_form':
              _pickString(raw, <String>['dosage_form', 'dosageForm']) ?? '',
          'strength': _pickString(raw, <String>['strength']) ?? '',
          'image_url':
              _pickString(raw, <String>['image_url', 'imageUrl']) ?? '',
          'uses': _pickString(raw, <String>['uses']) ?? '',
          'description': _pickString(raw, <String>['description']) ?? '',
        };

        medicines.add(Medicine.fromJson(normalized));
      }

      return medicines;
    } catch (_) {
      return null;
    }
  }

  Future<List<Medicine>?> _fetchMedicinesFromApi() async {
    if (_baseUrl.isEmpty) {
      return null;
    }

    try {
      final Uri uri = Uri.parse('$_baseUrl/medicines');
      final http.Response response =
          await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> rawList = _extractMedicinesList(decoded);

      return rawList
          .map((item) => Medicine.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> _fetchCategoriesFromApi() async {
    if (_baseUrl.isEmpty) {
      return null;
    }

    try {
      final Uri uri = Uri.parse('$_baseUrl/categories');
      final http.Response response =
          await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }

      if (decoded is Map<String, dynamic>) {
        final dynamic categories = decoded['categories'];
        if (categories is List) {
          return categories.map((item) => item.toString()).toList();
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Medicine>> _fetchMedicinesFromLocalJson() async {
    final String raw = await rootBundle.loadString('medicines_database.json');
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> list =
        decoded['medicines'] as List<dynamic>? ?? <dynamic>[];

    return list
        .map((item) => Medicine.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<dynamic> _extractMedicinesList(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic medicines = decoded['medicines'];
      if (medicines is List<dynamic>) {
        return medicines;
      }
    }

    return <dynamic>[];
  }

  List<String> _normalizeCategories(List<String> rawCategories) {
    final Set<String> unique = rawCategories
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    final List<String> normalized = unique.toList()..sort();
    return normalized;
  }

  int? _parseMedicineId(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  String? _pickString(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
      if (value != null && value is! String) {
        final String stringValue = value.toString().trim();
        if (stringValue.isNotEmpty) {
          return stringValue;
        }
      }
    }
    return null;
  }

  num? _pickNum(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = data[key];
      if (value is num) {
        return value;
      }
      if (value is String) {
        final num? parsed = num.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
