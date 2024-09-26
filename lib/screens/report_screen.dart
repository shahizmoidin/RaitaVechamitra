import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:raitavechamitra/models/payment.dart';

// Define a provider to manage payments
final paymentsProvider = StateProvider<List<Payment>>((ref) => []);

class ReportScreen extends ConsumerStatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  DateTimeRange? dateRange;
  String filterType = "All";

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentsProvider);
    final filteredPayments = _filterPaymentsByDateAndType(payments);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green[50]!], // Light green gradient background
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilterControls(),
            SizedBox(height: 16),
            _buildDownloadButtons(filteredPayments),
            SizedBox(height: 16),
            Expanded(child: _buildPaymentChart(filteredPayments)),
            if (filteredPayments.isEmpty)
              Center(
                child: Text(
                  'No data available for the selected filters',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
            else 
              _buildPaymentTable(filteredPayments),
          ],
        ),
      ),
    );
  }

  Row _buildFilterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700], // Button color
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => _pickDateRange(context),
          child: Text('Select Date Range'),
        ),
        DropdownButton<String>(
          value: filterType,
          items: ['All', 'Income', 'Expense']
              .map((String value) => DropdownMenuItem<String>(
                  value: value, child: Text(value)))
              .toList(),
          onChanged: (newValue) {
            setState(() {
              filterType = newValue!;
            });
          },
          style: TextStyle(color: Colors.green[800]),
          underline: Container(height: 2, color: Colors.green[700]),
        ),
      ],
    );
  }

  Row _buildDownloadButtons(List<Payment> filteredPayments) {
    return Row(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => _generatePdfReport(context, filteredPayments),
          child: Text('Download PDF Report'),
        ),
        SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => _exportToCSV(filteredPayments),
          child: Text('Export as CSV'),
        ),
      ],
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        dateRange = picked;
      });
    }
  }

  Future<void> _generatePdfReport(BuildContext context, List<Payment> payments) async {
    final pdf = pw.Document();
    final filteredPayments = _filterPaymentsByDateAndType(payments);

    double totalIncome = 0;
    double totalExpenses = 0;
    for (var payment in filteredPayments) {
      if (payment.type == PaymentType.credit) {
        totalIncome += payment.amount;
      } else {
        totalExpenses += payment.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Center(
            child: pw.Text('Raitavechamitra',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total Income: ₹${totalIncome.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.green)),
          pw.Text('Total Expenses: ₹${totalExpenses.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.red)),
          pw.SizedBox(height: 20),
          _buildPaymentTableForPDF(filteredPayments),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/payment_report.pdf');
    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  List<Payment> _filterPaymentsByDateAndType(List<Payment> payments) {
    if (dateRange != null) {
      payments = payments.where((payment) {
        return payment.date.isAfter(dateRange!.start) && payment.date.isBefore(dateRange!.end);
      }).toList();
    }

    if (filterType != "All") {
      PaymentType type = filterType == "Income" ? PaymentType.credit : PaymentType.debit;
      payments = payments.where((p) => p.type == type).toList();
    }

    return payments;
  }

  Future<void> _exportToCSV(List<Payment> payments) async {
    List<List<dynamic>> rows = [
      ['Date', 'Category', 'Type', 'Amount'],
    ];

    for (var payment in payments) {
      List<dynamic> row = [];
      row.add(DateFormat.yMMMd().format(payment.date));
      row.add(payment.category);
      row.add(payment.type == PaymentType.credit ? 'Income' : 'Expense');
      row.add('₹${payment.amount.toStringAsFixed(2)}');
      rows.add(row);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/payment_report.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    await FilePicker.platform.saveFile(
      dialogTitle: 'Save Payment Report CSV',
      fileName: 'payment_report.csv',
      initialDirectory: directory.path,
    );
  }

  pw.Widget _buildPaymentTableForPDF(List<Payment> payments) {
    return pw.Table.fromTextArray(
      headers: ['Date', 'Category', 'Type', 'Amount'],
      data: payments.map((payment) {
        return [
          DateFormat.yMMMd().format(payment.date),
          payment.category,
          payment.type == PaymentType.credit ? 'Income' : 'Expense',
          '₹${payment.amount.toStringAsFixed(2)}',
        ];
      }).toList(),
      cellAlignment: pw.Alignment.center, // Center align the text in table cells
      border: pw.TableBorder.all(color: PdfColors.grey), // Add border to table
    );
  }

  Widget _buildPaymentChart(List<Payment> payments) {
    if (payments.isEmpty) {
      return Center(child: Text('No payments to display'));
    }

    double totalIncome = payments.where((p) => p.type == PaymentType.credit).fold(0, (sum, p) => sum + p.amount);
    double totalExpenses = payments.where((p) => p.type == PaymentType.debit).fold(0, (sum, p) => sum + p.amount);

    return SfCircularChart(
      title: ChartTitle(
        text: 'Income vs Expenses',
        textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: TextStyle(color: Colors.green[700]), // Legend text color
      ),
      series: <CircularSeries>[
        PieSeries<ChartData, String>(
          dataSource: [
            ChartData('Income', totalIncome),
            ChartData('Expense', totalExpenses),
          ],
          xValueMapper: (ChartData data, _) => data.category,
          yValueMapper: (ChartData data, _) => data.amount,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        )
      ],
    );
  }

  Widget _buildPaymentTable(List<Payment> payments) {
    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(
              '${payment.category} - ₹${payment.amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: payment.type == PaymentType.credit ? Colors.green : Colors.red),
            ),
            subtitle: Text(DateFormat.yMMMd().format(payment.date)),
          ),
        );
      },
    );
  }
}

class ChartData {
  final String category;
  final double amount;

  ChartData(this.category, this.amount);
}
