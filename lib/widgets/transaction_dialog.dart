import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';

class TransactionDialog extends StatefulWidget {
  final String type;

  const TransactionDialog({
    super.key,
    required this.type,
  });

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedSubCategory;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final subCategories = budgetProvider.subCategories[widget.type] ?? [];
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return AlertDialog(
      title: Text(
        '${widget.type} Ekle',
        style: TextStyle(
          fontSize: isSmallScreen ? 18 : 22,
        ),
      ),
      content: SizedBox(
        width: isSmallScreen ? null : screenWidth * 0.4,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alt kategori seçici
              DropdownButtonFormField<String>(
                value: _selectedSubCategory,
                decoration: InputDecoration(
                  labelText: 'Alt Kategori',
                  labelStyle: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                items: subCategories.map((subCategory) {
                  return DropdownMenuItem(
                    value: subCategory,
                    child: Text(
                      subCategory,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir alt kategori seçin';
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Miktar girişi
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Miktar (₺)',
                  labelStyle: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  prefixIcon: Icon(
                    Icons.attach_money,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir miktar girin';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir miktar girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Not girişi
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Not (İsteğe bağlı)',
                  labelStyle: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  prefixIcon: Icon(
                    Icons.note,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İptal',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text);
              
              context.read<BudgetProvider>().addTransaction(
                category: budgetProvider.selectedCategory,
                type: widget.type,
                subCategory: _selectedSubCategory!,
                amount: amount,
                note: _noteController.text.isEmpty ? null : _noteController.text,
              );

              Navigator.pop(context);
            }
          },
          child: Text(
            'Ekle',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }
} 