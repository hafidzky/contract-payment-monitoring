import 'package:flutter/material.dart';
import 'app.dart';
import 'data/providers/contract_provider.dart'; 
import 'package:provider/provider.dart';
import 'data/providers/vendor_provider.dart';
import 'data/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final vendorProvider = VendorProvider();
  final contractProvider = ContractProvider();
  final authProvider = AuthProvider();
  
  await vendorProvider.fetchVendors();
  await contractProvider.loadContracts(); // ← jika ada method load

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: vendorProvider),
        ChangeNotifierProvider.value(value: contractProvider),
        ChangeNotifierProvider.value(value: authProvider),
        // provider lainnya...
      ],
      child: const PelindoVendorApp(),
    ),
  );
}