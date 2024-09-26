import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raitavechamitra/models/category.dart';

class CategoryForm extends StatefulWidget {
  @override
  _CategoryFormState createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Category'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveCategory(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCategory,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showErrorDialog('Please enter a category name.');
      return;
    }

    // Create a new Category instance
    final category = Category(
      id: '', // Firestore will generate an ID
      name: name,
    );

    try {
      // Save to Firestore
      final categoryRef = FirebaseFirestore.instance.collection('categories').doc();
      await categoryRef.set(category.toMap());

      // Optionally, you can get the ID assigned by Firestore
      final updatedCategory = category.copyWith(id: categoryRef.id);

      // Optionally, update the UI or state if necessary

      // Close the form and go back to the previous screen
      Navigator.of(context).pop(updatedCategory);
    } catch (error) {
      _showErrorDialog('Failed to save category. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Okay'),
          ),
        ],
      ),
    );
  }
}
