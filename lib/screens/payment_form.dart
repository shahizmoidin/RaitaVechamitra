import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:raitavechamitra/models/payment.dart';
import 'package:raitavechamitra/utils/localization.dart';

class PaymentForm extends StatefulWidget {
  final PaymentType type;
  final String userId;
  final Payment? payment;
  final VoidCallback? onSave;

  PaymentForm({required this.type, required this.userId, this.payment, this.onSave});

  @override
  _PaymentFormState createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  bool _isCustomCategory = false;

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      _amountController.text = widget.payment!.amount.toString();
      _descriptionController.text = widget.payment!.description ?? '';
      _selectedDate = widget.payment!.date;
      _selectedCategory = widget.payment!.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final category = _isCustomCategory
          ? _customCategoryController.text
          : _selectedCategory ?? 'No category';

      final payment = Payment(
        id: widget.payment?.id ?? '',
        category: category,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        date: _selectedDate,
        type: widget.type,
      );

      final paymentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('payments');

      if (widget.payment == null) {
        await paymentRef.add(payment.toMap());
      } else {
        await paymentRef.doc(widget.payment!.id).update(payment.toMap());
      }

      Navigator.pop(context); // Remove spinner

      if (widget.onSave != null) {
        widget.onSave!();
      }

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == PaymentType.credit;
    final themeColor = isIncome ? Colors.green[800] : Colors.red[800];
    final buttonColor = isIncome ? Colors.green[700] : Colors.red[700];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isIncome
              ? AppLocalizations.of(context).translate('add_income')
              : AppLocalizations.of(context).translate('add_expense'),
        style: TextStyle(color: Colors.white),),
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryDropdown(themeColor),
              if (_isCustomCategory) _buildCustomCategoryField(themeColor),
              SizedBox(height: 20),
              _buildAmountField(themeColor),
              SizedBox(height: 20),
              _buildDescriptionField(themeColor),
              SizedBox(height: 20),
              _buildDateSelector(themeColor),
              SizedBox(height: 20),
              _buildSaveButton(buttonColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(Color? themeColor) {
    final categories = [
      AppLocalizations.of(context).translate('farming'),
      AppLocalizations.of(context).translate('wages'),
      AppLocalizations.of(context).translate('rent'),
      AppLocalizations.of(context).translate('medical_expenses'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('select_category'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor),
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _isCustomCategory ? null : _selectedCategory,
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).translate('category'),
            labelStyle: TextStyle(color: themeColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: themeColor!),
            ),
            filled: true,
            fillColor: themeColor.withOpacity(0.1),
          ),
          onChanged: (value) {
            setState(() {
              _isCustomCategory = false;
              _selectedCategory = value;
            });
          },
          validator: (value) {
            if (!_isCustomCategory && (value == null || value.isEmpty)) {
              return AppLocalizations.of(context).translate('please_select_category');
            }
            return null;
          },
        ),
        SizedBox(height: 20),
        CheckboxListTile(
          title: Text(AppLocalizations.of(context).translate('enter_custom_category'),
              style: TextStyle(color: themeColor)),
          controlAffinity: ListTileControlAffinity.leading,
          value: _isCustomCategory,
          onChanged: (bool? value) {
            setState(() {
              _isCustomCategory = value ?? false;
              _selectedCategory = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCustomCategoryField(Color? themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _customCategoryController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).translate('custom_category'),
            labelStyle: TextStyle(color: themeColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: themeColor!),
            ),
            filled: true,
            fillColor: themeColor.withOpacity(0.1),
          ),
          validator: (value) {
            if (_isCustomCategory && (value == null || value.isEmpty)) {
              return AppLocalizations.of(context).translate('please_enter_custom_category');
            }
            return null;
          },
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAmountField(Color? themeColor) {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).translate('amount'),
        labelStyle: TextStyle(color: themeColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: themeColor!),
        ),
        filled: true,
        fillColor: themeColor!.withOpacity(0.1),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context).translate('please_enter_amount');
        }
        if (double.tryParse(value) == null) {
          return AppLocalizations.of(context).translate('please_enter_valid_number');
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField(Color? themeColor) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).translate('description'),
        labelStyle: TextStyle(color: themeColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: themeColor!),
        ),
        filled: true,
        fillColor: themeColor!.withOpacity(0.1),
      ),
    );
  }

  Widget _buildDateSelector(Color? themeColor) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2019),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).translate('date'),
          labelStyle: TextStyle(color: themeColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: themeColor!),
          ),
          filled: true,
          fillColor: themeColor!.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('yyyy/MM/dd').format(_selectedDate)),
            Icon(Icons.calendar_today, color: themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(Color? buttonColor) {
    return ElevatedButton(
      onPressed: _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(
        widget.payment == null
            ? AppLocalizations.of(context).translate('save_payment')
            : AppLocalizations.of(context).translate('update_payment'),
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
