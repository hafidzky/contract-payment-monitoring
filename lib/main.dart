import 'package:flutter/material.dart';
import 'app.dart';
import 'data/providers/contract_provider.dart'; 
import 'package:provider/provider.dart';
import 'data/providers/vendor_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final vendorProvider = VendorProvider();
  final contractProvider = ContractProvider(); // ← tambahkan ini
  
  await vendorProvider.loadVendors();
  await contractProvider.loadContracts(); // ← jika ada method load

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: vendorProvider),
        ChangeNotifierProvider.value(value: contractProvider), // ← tambahkan ini
        // provider lainnya...
      ],
      child: const PelindoVendorApp(),
    ),
  );
}