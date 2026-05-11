import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/contract/contract_list.dart'; 
import '../../features/contract/add/add_contract_step1.dart';
import '../../navigation/main_navigation.dart';
import '../../features/dashboard/dashboard_page.dart';

class AppRouter {
  static const String login = '/';
  static const String main = '/main';
  static const String adminDashboard = '/admin-dashboard';
  static const String contractList = '/contract-list';
  static const String addContract = '/add-contract';

  static Map<String, WidgetBuilder> get routes => {
    login:          (_) => const LoginPage(),
    main:           (_) => const MainNavigation(),
    adminDashboard: (_) => const AdminDashboardPage(),
    contractList:   (_) => const ContractListPage(),
    addContract:    (_) => const AddContractPage(),
  };
}