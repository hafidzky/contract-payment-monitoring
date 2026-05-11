import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/contract_provider.dart';
import 'widgets/metrics_grid.dart';
import 'widgets/urgency_section.dart';
import 'widgets/progress_section.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
    Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1100;
    final isMedium = screenSize.width > 600 && screenSize.width <= 1100;
    final provider = Provider.of<ContractProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Memuat data kontrak...",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDesktop),
          SliverToBoxAdapter(
            child: Padding(
              // ✅ Mobile padding lebih kecil
              padding: EdgeInsets.all(isDesktop ? 24.0 : isMedium ? 20.0 : 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(context),
                  SizedBox(height: isDesktop ? 24 : 12), 
                  MetricsGrid(isDesktop: isDesktop, isMedium: isMedium),
                  SizedBox(height: isDesktop ? 32 : 12), 
                  if (isDesktop)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: UrgencySection(isDesktop: isDesktop)),
                          const SizedBox(width: 24),
                          Expanded(flex: 5, child: ProgressSection()),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        UrgencySection(isDesktop: false),
                        SizedBox(height: isDesktop ? 24 : 12), 
                        ProgressSection(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDesktop) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;
    final titleSize = width > 1100 ? 28.0 : width > 600 ? 22.0 : 16.0; 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDesktop
            ? "Vendor Contract & Payment Monitoring"
            : "Vendor Contract & Payment Monitoring", 
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          "SEMANGAT! Pantau kontrak dan pembayaran dengan mudah.",
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
            fontSize: 14, 
          ),
        ),
      ],
    );
  }
}