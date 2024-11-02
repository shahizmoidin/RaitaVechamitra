import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:raitavechamitra/models/payment.dart';
import 'package:raitavechamitra/screens/help_screen.dart';
import 'package:raitavechamitra/screens/login_screen.dart';
import 'package:raitavechamitra/screens/reaminder_notification.dart';
import 'package:raitavechamitra/screens/reminder_screen.dart';
import 'package:raitavechamitra/screens/schemes_screen.dart';
import 'package:raitavechamitra/screens/weather_screen.dart';
import 'package:raitavechamitra/utils/localization.dart';
import 'package:raitavechamitra/widgets/payment_list_item.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raitavechamitra/widgets/income_expense_chart.dart';
import 'package:raitavechamitra/chart_enum.dart';
import 'package:raitavechamitra/screens/profile_screen.dart';
import 'package:raitavechamitra/screens/settings_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'payment_form.dart';

// State for the authenticated user
final authUserProvider = StateProvider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

// State for user document from Firestore
final userProvider = StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) {
    return Stream.empty();
  }
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
});

// State for payments from Firestore
final paymentsProvider = StreamProvider.autoDispose<List<Payment>>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('payments')
      .orderBy('date')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Payment(
              id: doc.id,
              category: data['category'],
              amount: data['amount'],
              description: data['description'],
              date: (data['date'] as Timestamp).toDate(),
              type: data['type'] == 'credit' ? PaymentType.credit : PaymentType.debit,
            );
          }).toList());
});

// Home screen widget
class HomeScreen extends ConsumerStatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  ChartType _chartType = ChartType.pie;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: DateTime.now().day - 1)),
    end: DateTime.now(),
  );
  double _expenseLimit = 500.0;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        ref.invalidate(paymentsProvider);
        ref.invalidate(userProvider);
        ref.read(authUserProvider.notifier).state = null;
      } else {
        ref.read(authUserProvider.notifier).state = user;
        ref.refresh(userProvider);
        ref.refresh(paymentsProvider);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index); // Sync with PageView
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  void _openSetting() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await _confirmLogout();
    if (shouldLogout == true) {
      ref.invalidate(paymentsProvider);
      ref.invalidate(userProvider);
      ref.read(authUserProvider.notifier).state = null;

      await FirebaseAuth.instance.signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<bool?> _confirmLogout() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('sign_out')),
        content: Text(AppLocalizations.of(context).translate('are_you_sure')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).translate('sign_out')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(authUserProvider, (previousUser, newUser) {
      if (newUser == null) {
        ref.invalidate(paymentsProvider);
        ref.invalidate(userProvider);
      }
    });
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onItemTapped,
        children: [
          _buildHomeBody(),
          ScheduleNotificationScreen(),
          WeatherScreen(),
          SchemeScreen(),
          HealthReminderScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _selectedIndex == 0 ? _buildFAB() : null,
    );
  }

  AppBar _buildAppBar() {
  return AppBar(
    title: Text(
      AppLocalizations.of(context).translate('title'),
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    centerTitle: true,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),

    // Add leading for help icon on the left side
    leading: IconButton(
      icon: Icon(Icons.help_outline, color: Colors.white),
      onPressed: () {
        _openHelpScreen(); // Open the help screen when the help icon is pressed
      },
    ),

    actions: [
      IconButton(
  icon: Icon(Icons.download, color: Colors.white),
  onPressed: () async {
    await _showYearSelectionDialog(ref);
  },
),

      PopupMenuButton<int>(
        icon: Icon(Icons.person, color: Colors.white),
        onSelected: (item) {
          if (item == 0) {
            _openProfile();
          } else if (item == 1) {
            _openSetting();
          } else if (item == 2) {
            _logout();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 0, child: Text(AppLocalizations.of(context).translate('profile'))),
          PopupMenuItem(value: 1, child: Text(AppLocalizations.of(context).translate('settings'))),
          PopupMenuItem(value: 2, child: Text(AppLocalizations.of(context).translate('sign_out'))),
        ],
      ),
    ],
  );
}

Future<void> _showYearSelectionDialog(WidgetRef ref) async {
  int selectedYear = DateTime.now().year; // Default to current year
  List<int> availableYears = List.generate(
    DateTime.now().year - 2019 + 1, // Adjust range based on how many years back you want
    (index) => DateTime.now().year - index,
  );

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        backgroundColor: Colors.green[50], // Light background color
        title: Text(
          "Select Year",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[800], // Dark green color
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<int>(
                value: selectedYear,
                onChanged: (int? newYear) {
                  if (newYear != null) {
                    setState(() => selectedYear = newYear);
                  }
                },
                items: availableYears.map((year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green[900], // Text color for dropdown items
                      ),
                    ),
                  );
                }).toList(),
                icon: Icon(Icons.arrow_drop_down, color: Colors.green[800]),
                underline: SizedBox(),
                isExpanded: true,
                dropdownColor: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.green[700], // Text color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _downloadPDF(ref, selectedYear); // Call _downloadPDF with selected year
            },
            child: Text(
              "Download",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}


// Function to navigate to the Help Screen
void _openHelpScreen() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => HelpScreen()), // Navigate to the help screen
  );
}

Future<void> _downloadPDF(WidgetRef ref, int selectedYear) async {
  final pdf = pw.Document();

  // Load logo and fonts for multi-language support
  final Uint8List logoBytes = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
  final ttfEnglish = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"));
  
  // Filter payments data by selected year
  final payments = ref.watch(paymentsProvider).asData?.value ?? [];
  final filteredPayments = payments.where((payment) => payment.date.year == selectedYear).toList();

  // Initialize monthly data for income and expense
  final monthlyIncome = List<double>.filled(12, 0);
  final monthlyExpense = List<double>.filled(12, 0);
  double totalIncome = 0.0;
  double totalExpense = 0.0;

  // Group payments by month and type (income/expense)
  for (var payment in filteredPayments) {
    final monthIndex = payment.date.month - 1;
    if (payment.type == PaymentType.credit) {
      monthlyIncome[monthIndex] += payment.amount;
      totalIncome += payment.amount;
    } else if (payment.type == PaymentType.debit) {
      monthlyExpense[monthIndex] += payment.amount;
      totalExpense += payment.amount;
    }
  }

  final netProfit = totalIncome - totalExpense;
  final profitabilityStatus = netProfit > 0 ? "Profit" : netProfit < 0 ? "Loss" : "Break-even";
  final profitabilityAmount = 'Rs ${netProfit.abs().toStringAsFixed(2)}';

  // Add content to PDF
  pdf.addPage(
    pw.Page(
      theme: pw.ThemeData.withFont(base: ttfEnglish),
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Image(pw.MemoryImage(logoBytes), height: 80),
          ),
          pw.SizedBox(height: 10),

          // Centered "Annual Balance Sheet" Title
          pw.Center(
            child: pw.Text(
              'Annual Balance Sheet - $selectedYear',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: ttfEnglish),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated on ${DateFormat.yMMMMd().format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 16, font: ttfEnglish),
          ),
          pw.SizedBox(height: 20),

          // Monthly Income & Expense Table
          pw.Text('Monthly Income & Expense Report', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: ttfEnglish)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              // Table Header
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: pw.Text('Month', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfEnglish)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: pw.Text('Income', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfEnglish)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: pw.Text('Expense', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfEnglish)),
                  ),
                ],
              ),
              
              // Monthly Data Rows
              for (var i = 0; i < 12; i++)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8.0),
                      child: pw.Text(DateFormat.MMMM().format(DateTime(0, i + 1)), style: pw.TextStyle(fontSize: 12, font: ttfEnglish)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8.0),
                      child: pw.Text('Rs ${monthlyIncome[i].toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, font: ttfEnglish)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8.0),
                      child: pw.Text('Rs ${monthlyExpense[i].toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, font: ttfEnglish)),
                    ),
                  ],
                ),
              
              // Total Row
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: pw.Text('Total', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfEnglish)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: pw.Text('Rs ${totalIncome.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfEnglish)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: pw.Text('Rs ${totalExpense.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfEnglish)),
                  ),
                ],
              ),

              // Profit/Loss Row
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: pw.Text('Profit/Loss', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: ttfEnglish)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: pw.Text(
                      profitabilityAmount,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: netProfit > 0 ? PdfColors.green : PdfColors.red,
                        font: ttfEnglish,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: pw.Text(
                      profitabilityStatus,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: netProfit > 0 ? PdfColors.green : netProfit < 0 ? PdfColors.red : PdfColors.grey,
                        font: ttfEnglish,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // Save and share the PDF
  await Printing.sharePdf(bytes: await pdf.save(), filename: 'annual_balance_sheet_$selectedYear.pdf');
}



  Widget _buildHomeBody() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer(
        builder: (context, ref, _) {
          final userSnapshot = ref.watch(userProvider);
          final paymentsSnapshot = ref.watch(paymentsProvider);

          return paymentsSnapshot.when(
            error: (error, stackTrace) => Center(child: Text('Error loading payments: $error')),
            data: (payments) {
              final filteredPayments = payments.where((payment) {
                return payment.date.isAfter(_dateRange.start.subtract(Duration(days: 1))) &&
                       payment.date.isBefore(_dateRange.end.add(Duration(days: 1)));
              }).toList();

              double income = 0;
              double expense = 0;
              for (var payment in filteredPayments) {
                if (payment.type == PaymentType.credit) {
                  income += payment.amount;
                } else if (payment.type == PaymentType.debit) {
                  expense += payment.amount;
                }
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreeting(userSnapshot),
                      SizedBox(height: 16),
                      _buildIncomeExpenseRow(income, expense),
                      SizedBox(height: 20),
                      _buildChart(filteredPayments),
                      SizedBox(height: 20),
                      _buildDateRangeSelector(),
                      SizedBox(height: 16),
                      _buildPaymentList(filteredPayments),
                      SizedBox(height: 16),
                      _buildExpenseLimit(expense),
                      SizedBox(height: 16),
                      _buildRecentTransactions(filteredPayments),
                    ],
                  ),
                ),
              );
            },
            loading: () => _buildShimmerLoading(),
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _buildAddPaymentOptions(),
        );
      },
      child: Icon(Icons.add),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildAddPaymentOptions() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.add, color: Colors.green),
            title: Text(AppLocalizations.of(context).translate('add_income')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentForm(
                    type: PaymentType.credit,
                    userId: ref.read(authUserProvider)?.uid ?? '',
                  ),
                ),
              ).then((_) => ref.refresh(paymentsProvider));
            },
          ),
          ListTile(
            leading: Icon(Icons.remove, color: Colors.red),
            title: Text(AppLocalizations.of(context).translate('add_expense')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentForm(
                    type: PaymentType.debit,
                    userId: ref.read(authUserProvider)?.uid ?? '',
                  ),
                ),
              ).then((_) => ref.refresh(paymentsProvider));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _handleChooseDateRange,
          icon: Icon(Icons.date_range),
          label: Text(
            '${DateFormat.yMMMd().format(_dateRange.start)} - ${DateFormat.yMMMd().format(_dateRange.end)}',
          ),
        ),
      ],
    );
  }

  void _handleChooseDateRange() async {
    final DateTimeRange? newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (newDateRange != null) {
      setState(() {
        _dateRange = newDateRange;
      });
      ref.refresh(paymentsProvider);  // Refresh payments after date range change
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 10.0),
            title: Container(height: 15, color: Colors.white),
            subtitle: Container(height: 10, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildGreeting(AsyncValue<DocumentSnapshot<Map<String, dynamic>>> userSnapshot) {
    return Consumer(
      builder: (context, ref, _) {
        final data = userSnapshot.when(
          data: (snapshot) => snapshot.data() as Map<String, dynamic>?,
          loading: () => null,
          error: (error, stackTrace) => null,
        );

        final name = data?['name'] ?? AppLocalizations.of(context).translate('farmer');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppLocalizations.of(context).translate('hello')} $name",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIncomeExpenseRow(double income, double expense) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildCard(AppLocalizations.of(context).translate('income'), income, Colors.green)),
        SizedBox(width: 16),
        Expanded(child: _buildCard(AppLocalizations.of(context).translate('expense'), expense, Colors.red)),
      ],
    );
  }

  Widget _buildCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Payment> payments) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        setState(() {
          _chartType = _chartType == ChartType.pie ? ChartType.line : ChartType.pie;
        });
      },
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        child: IncomeExpenseChart(
          income: payments.where((p) => p.type == PaymentType.credit).fold(0.0, (sum, p) => sum + p.amount),
          expense: payments.where((p) => p.type == PaymentType.debit).fold(0.0, (sum, p) => sum + p.amount),
          payments: payments,
          chartType: _chartType,
        ),
      ),
    );
  }

  Widget _buildPaymentList(List<Payment> payments) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        return PaymentListItem(
          onTap: () {},
          payment: payments[index],
          onDelete: (payment) {
            _showDeleteDialog(payment);
          },
        );
      },
    );
  }

  void _showDeleteDialog(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete_payment')),
        content: Text(AppLocalizations.of(context).translate('are_you_sure_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              _deletePayment(payment);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate('delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deletePayment(Payment payment) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(ref.watch(authUserProvider)?.uid)
          .collection('payments')
          .doc(payment.id)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).translate('error_deleting_payment')}: $e')));
    }
  }

  Widget _buildExpenseLimit(double totalExpense) {
    double percentUsed = (totalExpense / _expenseLimit) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${AppLocalizations.of(context).translate('expense_limit')}: ₹${_expenseLimit.toStringAsFixed(2)}",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentUsed / 100,
          backgroundColor: Colors.grey[300],
          color: percentUsed > 100 ? Colors.red : Colors.green,
          minHeight: 10,
        ),
        SizedBox(height: 8),
        Text(
          "${AppLocalizations.of(context).translate('used_limit')}: ${percentUsed.toStringAsFixed(1)}%",
          style: TextStyle(fontSize: 14, color: percentUsed > 100 ? Colors.red : Colors.black),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(List<Payment> payments) {
    final recentPayments = payments.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('recent_transactions'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: recentPayments.length,
          itemBuilder: (context, index) {
            final payment = recentPayments[index];
            return ListTile(
              title: Text(payment.category),
              subtitle: Text(DateFormat.yMMMd().format(payment.date)),
              trailing: Text(
                '₹${payment.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: payment.type == PaymentType.credit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.green[800],
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.green[50],
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: AppLocalizations.of(context).translate('home'),
        ),
         BottomNavigationBarItem(
          icon: Icon(Icons.notification_add),
          label: AppLocalizations.of(context).translate('notify'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud),
          label: AppLocalizations.of(context).translate('weather'),
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.article),
          label: AppLocalizations.of(context).translate('schemes'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.health_and_safety),
          label: AppLocalizations.of(context).translate('health'),
        ),
      ],
    );
  }
}
