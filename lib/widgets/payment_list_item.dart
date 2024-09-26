import 'package:flutter/material.dart';
import 'package:raitavechamitra/models/payment.dart';
import 'package:raitavechamitra/widgets/currency.dart';

class PaymentListItem extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;
  final void Function(Payment) onDelete;

  const PaymentListItem({
    Key? key,
    required this.payment,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shadowColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: payment.type == PaymentType.credit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            payment.type == PaymentType.credit ? Icons.arrow_upward : Icons.arrow_downward,
            color: payment.type == PaymentType.credit ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                payment.description.isNotEmpty ? payment.description : 'No description',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            CurrencyText(
              payment.amount,
              style: TextStyle(
                color: payment.type == PaymentType.credit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              currencySymbol: '₹ ',
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            payment.category.isNotEmpty ? payment.category : 'No category',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => onDelete(payment),
        ),
      ),
    );
  }
}
