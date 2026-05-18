import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://10.201.42.44:8000/api';
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json'},
        body: {'username': username, 'password': password},
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setLoading(false);
        return {'success': true, 'data': data};
      } else {
        setLoading(false);
        return {'success': false, 'message': data['message'] ?? 'Login Gagal'};
      }
    } catch (e) {
      setLoading(false);
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }
}