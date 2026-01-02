/// 통계 화면
/// StatsScreen.tsx를 Flutter로 변환
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 통계 화면 위젯
class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // 기간 선택 (주간/월간)
  bool isWeekly = true;

  // 주간 데이터
  final List<Map<String, dynamic>> weeklyData = [
    {'name': '월', 'calories': 1800, 'exercise': 300, 'weight': 72.5},
    {'name': '화', 'calories': 2000, 'exercise': 400, 'weight': 72.3},
    {'name': '수', 'calories': 1900, 'exercise': 350, 'weight': 72.2},
    {'name': '목', 'calories': 2100, 'exercise': 450, 'weight': 72.0},
    {'name': '금', 'calories': 1850, 'exercise': 320, 'weight': 71.9},
    {'name': '토', 'calories': 2200, 'exercise': 500, 'weight': 71.8},
    {'name': '일', 'calories': 1950, 'exercise': 380, 'weight': 71.7},
  ];

  // 월간 데이터 (평균)
  final List<Map<String, dynamic>> monthlyData = [
    {'name': '1주', 'calories': 1950, 'exercise': 350, 'weight': 72.5},
    {'name': '2주', 'calories': 1971, 'exercise': 371, 'weight': 72.0},
    {'name': '3주', 'calories': 1993, 'exercise': 364, 'weight': 71.5},
    {'name': '4주', 'calories': 2014, 'exercise': 386, 'weight': 71.0},
  ];

  @override
  Widget build(BuildContext context) {
    final data = isWeekly ? weeklyData : monthlyData;

    // 통계 계산
    final avgCalories = (data.fold<double>(0, (sum, item) => sum + item['calories']) / data.length).round();
    final avgExercise = (data.fold<double>(0, (sum, item) => sum + item['exercise']) / data.length).round();
    final weightChange = data.last['weight'] - data.first['weight'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('통계'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 기간 선택
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPeriodButton('주간', isWeekly, () {
                      setState(() => isWeekly = true);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPeriodButton('월간', !isWeekly, () {
                      setState(() => isWeekly = false);
                    }),
                  ),
                ],
              ),
            ),

            // 통계 요약 카드
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      '평균 칼로리',
                      '$avgCalories kcal',
                      '+5%',
                      true,
                      Colors.orange,
                      Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      '평균 운동',
                      '$avgExercise kcal',
                      '+8%',
                      true,
                      Colors.blue,
                      Icons.fitness_center,
                    ),
                  ),
                ],
              ),
            ),

            // 체중 변화 카드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSummaryCard(
                '체중 변화',
                '${weightChange.toStringAsFixed(1)} kg',
                '${(weightChange / data.first['weight'] * 100).toStringAsFixed(1)}%',
                weightChange < 0,
                Colors.green,
                Icons.monitor_weight,
              ),
            ),

            const SizedBox(height: 16),

            // 칼로리 차트
            _buildChartCard(
              '칼로리 섭취',
              data,
              'calories',
              Colors.orange,
            ),

            const SizedBox(height: 16),

            // 운동 차트
            _buildChartCard(
              '운동 칼로리',
              data,
              'exercise',
              Colors.blue,
            ),

            const SizedBox(height: 16),

            // 체중 차트
            _buildChartCard(
              '체중 변화',
              data,
              'weight',
              Colors.green,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 기간 선택 버튼
  Widget _buildPeriodButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  /// 요약 카드
  Widget _buildSummaryCard(
    String title,
    String value,
    String change,
    bool isPositive,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 차트 카드
  Widget _buildChartCard(
    String title,
    List<Map<String, dynamic>> data,
    String dataKey,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: dataKey == 'weight' ? 0.5 : (dataKey == 'calories' ? 500 : 200),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[value.toInt()]['name'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: dataKey == 'weight' ? 0.5 : (dataKey == 'calories' ? 500 : 100),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: _getMinY(data, dataKey),
                maxY: _getMaxY(data, dataKey),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value[dataKey].toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 차트 최소값 계산
  double _getMinY(List<Map<String, dynamic>> data, String dataKey) {
    final values = data.map((e) => e[dataKey].toDouble()).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    
    if (dataKey == 'weight') {
      return min - 1;
    }
    return 0;
  }

  /// 차트 최대값 계산
  double _getMaxY(List<Map<String, dynamic>> data, String dataKey) {
    final values = data.map((e) => e[dataKey].toDouble()).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    
    if (dataKey == 'weight') {
      return max + 1;
    }
    return (max * 1.2).roundToDouble();
  }
}
