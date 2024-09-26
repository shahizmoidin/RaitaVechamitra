import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final PaymentType type;

  Payment({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.type,
  });

  // Factory constructor for creating a Payment instance from Firestore document
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: PaymentType.values.firstWhere(
        (e) => e.toString() == 'PaymentType.${data['type']}',
      ),
    );
  }

  // Method to convert Payment to Firestore document format
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date),
      'type': type.toString().split('.').last,
    };
  }
}

enum PaymentType { credit, debit }
