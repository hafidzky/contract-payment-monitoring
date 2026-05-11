import 'package:flutter/material.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';

class PelindoVendorApp extends StatelessWidget {
  const PelindoVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelindo Vendor Monitoring',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.login,
      routes: AppRouter.routes,
    );
  }
}