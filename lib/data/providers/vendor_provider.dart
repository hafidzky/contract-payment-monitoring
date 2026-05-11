import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Vendor {
  final String name;
  final String category;

  Vendor({
    required this.name,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
    'name':     name,
    'category': category,
  };

  factory Vendor.fromMap(Map<String, dynamic> map) => Vendor(
    name:     map['name'] ?? '',
    category: map['category'] ?? '',
  );
}

class VendorProvider with ChangeNotifier {
  final List<Vendor> _vendors = [];
  bool _isLoading = false;
  bool _isLoaded  = false;
  static const String _storageKey = 'vendors_data';

  List<Vendor> get vendors  => List.unmodifiable(_vendors);
  bool get isLoading        => _isLoading;
  bool get isLoaded         => _isLoaded;

  Future<void> loadVendors() async {
    if (_isLoaded || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _vendors.clear();
        _vendors.addAll(decoded.map((e) => Vendor.fromMap(e)).toList());
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('[VendorProvider] loadVendors error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_vendors.map((v) => v.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('[VendorProvider] _save error: $e');
    }
  }

  Future<void> addVendor(Vendor vendor) async {
    _vendors.insert(0, vendor);
    await _save();
    notifyListeners();
  }

  Future<void> updateVendor(int index, Vendor updated) async {
    if (index < 0 || index >= _vendors.length) return;
    _vendors[index] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> deleteVendor(int index) async {
    if (index < 0 || index >= _vendors.length) return;
    _vendors.removeAt(index);
    await _save();
    notifyListeners();
  }
}