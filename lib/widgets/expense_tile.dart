import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class IncomeExpenseChart extends StatelessWidget {
  final double income;
  final double expense;

  IncomeExpenseChart({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              color: Colors.green,
              value: income,
              title: 'Income',
              radius: 60,
            ),
            PieChartSectionData(
              color: Colors.red,
              value: expense,
              title: 'Expense',
              radius: 60,
            ),
          ],
        ),
      ),
    );
  }
}
