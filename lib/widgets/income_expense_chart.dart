import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:raitavechamitra/chart_enum.dart';
import 'package:raitavechamitra/models/payment.dart';
import 'package:intl/intl.dart';

class IncomeExpenseChart extends StatelessWidget {
  final double income;
  final double expense;
  final List<Payment> payments;
  final ChartType chartType;

  IncomeExpenseChart({
    required this.income,
    required this.expense,
    required this.payments,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      constraints: BoxConstraints(
        maxHeight: 300,
        maxWidth: double.infinity,
      ),
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              child: chartType == ChartType.pie
                  ? _buildPieChart(context)
                  : _buildLineChart(context),
            ),
          ),
          if (chartType == ChartType.pie)
            _buildPieChartLegend(), // Add the legend outside the pie chart
        ],
      ),
    );
  }

  // Build the pie chart with category indicators outside
  Widget _buildPieChart(BuildContext context) {
    final Map<String, double> categoryTotals = {};

    for (var payment in payments) {
      final amount = payment.type == PaymentType.credit ? payment.amount : -payment.amount;
      categoryTotals[payment.category] = (categoryTotals[payment.category] ?? 0) + amount;
    }

    return PieChart(
      PieChartData(
        sections: _buildPieChartSections(categoryTotals),
        borderData: FlBorderData(show: false),
        sectionsSpace: 4,
        centerSpaceRadius: 50,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Optionally handle interactions like touches here
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> categoryTotals) {
    final totalIncomeExpense = income + expense.abs();

    return categoryTotals.entries.map((entry) {
      final index = categoryTotals.keys.toList().indexOf(entry.key);
      final percentage = (entry.value.abs() / totalIncomeExpense) * 100;

      return PieChartSectionData(
        color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.9),
        value: entry.value.abs(),
        title: '',
        radius: 60,
      );
    }).toList();
  }

  // Build the legend for the pie chart
  Widget _buildPieChartLegend() {
    final Map<String, double> categoryTotals = {};

    for (var payment in payments) {
      final amount = payment.type == PaymentType.credit ? payment.amount : -payment.amount;
      categoryTotals[payment.category] = (categoryTotals[payment.category] ?? 0) + amount;
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: categoryTotals.entries.map((entry) {
        final index = categoryTotals.keys.toList().indexOf(entry.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.primaries[index % Colors.primaries.length],
              ),
            ),
            SizedBox(width: 8),
            Text('${entry.key} (${entry.value.abs().toStringAsFixed(0)} ₹)'),
          ],
        );
      }).toList(),
    );
  }

  // Build the line chart with grid lines and enhanced tooltips
  Widget _buildLineChart(BuildContext context) {
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final incomeMap = <DateTime, double>{};
    final expenseMap = <DateTime, double>{};

    for (var payment in payments) {
      final date = payment.date;
      final value = payment.amount;

      if (payment.type == PaymentType.credit) {
        incomeMap[date] = (incomeMap[date] ?? 0) + value;
      } else {
        expenseMap[date] = (expenseMap[date] ?? 0) + value;
      }
    }

    final sortedDates = [...incomeMap.keys, ...expenseMap.keys].toSet().toList()
      ..sort((a, b) => a.compareTo(b));

    for (var i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      incomeSpots.add(FlSpot(i.toDouble(), incomeMap[date] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), expenseMap[date] ?? 0));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.3),
              gradient: LinearGradient(
                colors: [Colors.green.withOpacity(0.3), Colors.greenAccent.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.3),
              gradient: LinearGradient(
                colors: [Colors.red.withOpacity(0.3), Colors.redAccent.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < sortedDates.length) {
                  final date = sortedDates[index];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Date: ${DateFormat('MM/dd').format(sortedDates[spot.spotIndex])}\nValue: ₹${spot.y.toStringAsFixed(2)}',
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
