import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String currencySymbol;

  CurrencyText(this.amount, {this.style, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(symbol: currencySymbol);
    return Text(
      formatCurrency.format(amount),
      style: style,
    );
  }
}
