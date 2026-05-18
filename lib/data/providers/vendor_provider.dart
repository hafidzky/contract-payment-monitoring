import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Ini jembatan ke Laravel-mu

class Vendor {
  final int? id; // Wajib ada karena MySQL menggunakan ID
  final String name;
  final String category;

  Vendor({
    this.id,
    required this.name,
    this.category = '-', // Default, karena di Laravelmu tidak ada kolom ini
  });

  factory Vendor.fromMap(Map<String, dynamic> map) => Vendor(
    id: map['id'],
    name: map['name'] ?? '',
    category: map['category'] ?? '-',
  );
}

class VendorProvider with ChangeNotifier {
  final List<Vendor> _vendors = [];
  bool _isLoading = false;

  List<Vendor> get vendors => List.unmodifiable(_vendors);
  bool get isLoading => _isLoading;

  // MESIN UTAMA: Mengambil data dari Laravel
  Future<void> fetchVendors() async {
    _isLoading = true;

    // Perhatikan: notifyListeners dihilangkan di sini agar tidak konflik saat render pertama
    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/vendors');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['data'];

        _vendors.clear();
        _vendors.addAll(data.map((e) => Vendor.fromMap(e)).toList());
      } else {
        debugPrint('Gagal mengambil data dari server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[VendorProvider] fetchVendors error: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Baru refresh layar setelah data didapat
    }
  }

  // --- Fungsi Add, Update, Delete untuk sementara kita biarkan kosong / sekadar update UI lokal ---
  // Fokusmu HANYA menampilkan data MySQL ke layar terlebih dahulu.
  // MESIN PENAMBAH DATA KE MYSQL
  Future<void> addVendor(Vendor vendor) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/vendors');

      // Kita menembakkan POST request ke Laravel
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Wajib ada untuk POST JSON
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': vendor.name,
          // 'contact_person': vendor.contactPerson, // Buka jika kamu butuh di masa depan
          // 'phone_number': vendor.phoneNumber,
        }),
      );

      if (response.statusCode == 201) {
        await fetchVendors();
      } else {
        debugPrint('Server menolak data: ${response.body}');
      }
    } catch (e) {
      debugPrint('[VendorProvider] Gagal POST addVendor: $e');
    }
  }

  Future<void> updateVendor(int index, Vendor updated) async {
    if (index < 0 || index >= _vendors.length) return;
    _vendors[index] = updated;
    notifyListeners();
  }

  Future<bool> deleteVendor(int id) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/vendors/$id');
      final response = await http.delete(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchVendors(); // Sinkronisasi data terbaru
        return true; // Berhasil!
      } else {
        debugPrint('Server menolak hapus: ${response.body}');
        return false; // Gagal!
      }
    } catch (e) {
      debugPrint('[VendorProvider] Gagal DELETE: $e');
      return false; // Gagal!
    }
  }
}