import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:raitavechamitra/models/payment.dart';
import 'package:raitavechamitra/screens/login_screen.dart';
import 'package:raitavechamitra/screens/reminder_screen.dart';
import 'package:raitavechamitra/screens/report_screen.dart';
import 'package:raitavechamitra/screens/weather_screen.dart';
import 'package:raitavechamitra/widgets/payment_list_item.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raitavechamitra/widgets/income_expense_chart.dart';
import 'package:raitavechamitra/chart_enum.dart';
import 'package:raitavechamitra/screens/profile_screen.dart';
import 'package:raitavechamitra/screens/settings_screen.dart';
import 'payment_form.dart';

// Provider to fetch the authenticated user's data from FirebaseAuth and Firestore
final authUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

// Provider for user data from Firestore
final userProvider = StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) {
    return Stream.empty(); // Return an empty stream if user is null
  }
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
});
// Provider for payments data
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
  double _expenseLimit = 500.0; // Example expense limit

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WeatherScreen()),

      );
    }
    else if(index==3){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HealthReminderScreen()),

      );

    }
    else if(index==4){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportScreen()),

      );

    }
  }

  @override
  Widget build(BuildContext context) {
    final userSnapshot = ref.watch(userProvider);
    final paymentsSnapshot = ref.watch(paymentsProvider);

    return Scaffold(
      appBar: _buildAppBar(userSnapshot),
      body: paymentsSnapshot.when(
        data: (payments) {
          double income = 0;
          double expense = 0;
          for (var payment in payments) {
            if (payment.type == PaymentType.credit) {
              income += payment.amount;
            } else {
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
                  _buildChart(payments),
                  SizedBox(height: 20),
                  _buildDateRangeSelector(),
                  SizedBox(height: 16),
                  _buildPaymentList(payments),
                  SizedBox(height: 16),
                  _buildExpenseLimit(expense),
                  SizedBox(height: 16),
                  _buildRecentTransactions(payments),
                ],
              ),
            ),
          );
        },
        loading: () => _buildShimmerLoading(),
        error: (err, _) => Center(child: Text('Error loading payments')),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFAB(),
    );
  }

  AppBar _buildAppBar(AsyncValue<DocumentSnapshot<Map<String, dynamic>>> userSnapshot) {
    return AppBar(
      title: Text(
        'Raitavechamitra',
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
      actions: [
        PopupMenuButton<int>(
          icon: Icon(Icons.person, color: Colors.white),
          onSelected: (item) {
            if (item == 0) {
              _openProfile();
            } else if (item == 1) {
              _openSettings();
            } else if (item == 2) {
              _logout();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 0, child: Text('Profile')),
            PopupMenuItem(value: 1, child: Text('Settings')),
            PopupMenuItem(value: 2, child: Text('Logout')),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(AsyncValue<DocumentSnapshot<Map<String, dynamic>>> userSnapshot) {
    return userSnapshot.when(
      data: (snapshot) {
        final data = snapshot.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Farmer';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi, $name",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            Text(
              "Here's your financial summary",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text("Error loading user data"),
    );
  }

  Widget _buildIncomeExpenseRow(double income, double expense) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildCard('Income', income, Colors.green)),
        SizedBox(width: 16),
        Expanded(child: _buildCard('Expense', expense, Colors.red)),
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
            FirebaseFirestore.instance
                .collection('users')
                .doc(ref.watch(authUserProvider)?.uid)
                .collection('payments')
                .doc(payment.id)
                .delete();
          },
        );
      },
    );
  }

  Widget _buildExpenseLimit(double totalExpense) {
    double percentUsed = (totalExpense / _expenseLimit) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Daily Expense Limit: ₹${_expenseLimit.toStringAsFixed(2)}",
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
          "You have used ${percentUsed.toStringAsFixed(1)}% of your daily limit.",
          style: TextStyle(fontSize: 14, color: percentUsed > 100 ? Colors.red : Colors.black),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(List<Payment> payments) {
    final recentPayments = payments.take(3).toList(); // Get the latest 3 transactions

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Transactions",
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
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.green[800],
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.green[50],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
        BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Schemes'),
        BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: 'Health'),
        BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
      ],
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
            title: Text('Add Income'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentForm(
                    type: PaymentType.credit,
                    userId: ref.watch(authUserProvider)?.uid ?? '',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.remove, color: Colors.red),
            title: Text('Add Expense'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentForm(
                    type: PaymentType.debit,
                    userId: ref.watch(authUserProvider)?.uid ?? '',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleChooseDateRange() async {
    final DateTimeRange? newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
    );
    if (newDateRange != null) {
      setState(() {
        _dateRange = newDateRange;
      });
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

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  void _logout() {
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }
}
