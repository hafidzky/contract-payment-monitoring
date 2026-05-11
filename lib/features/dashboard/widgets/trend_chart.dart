import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendChart extends StatelessWidget {
  final List<double> data;
  final Color color;

  const TrendChart({
    super.key, 
    required this.data, 
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50, // Tinggi grafik tetap proporsional
      width: double.infinity,
      child: LineChart(
        LineChartData(
          // 1. Menghilangkan semua garis grid dan angka di pinggir agar "Clean"
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          
          // 2. Mengatur padding grafik agar tidak terpotong
          lineTouchData: const LineTouchData(enabled: false), // Nonaktifkan interaksi (opsional untuk monitor)
          
          lineBarsData: [
            LineChartBarData(
              // Mengubah List<double> menjadi titik koordinat (Spots)
              spots: data.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              
              isCurved: true, 
              curveSmoothness: 0.4,
              color: color, // Warna mengikuti parameter (misal: Teal)
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false), // Sembunyikan titik koordinat
              
              // 3. EFEK GRADIENT (Bayangan di bawah garis)
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.3), // Terang di dekat garis
                    color.withValues(alpha: 0.0), // Memudar ke bawah
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}