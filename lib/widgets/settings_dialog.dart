import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      child: Container(
        width: isSmallScreen ? null : screenWidth * 0.4,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  size: isSmallScreen ? 24 : 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ayarlar',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Kategoriler',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<BudgetProvider>(
              builder: (context, budgetProvider, child) {
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ReorderableListView(
                    shrinkWrap: true,
                    onReorder: budgetProvider.reorderCategories,
                    children: budgetProvider.categories.map((category) {
                      final isGeneral = category == 'Genel';
                      return ListTile(
                        key: Key(category),
                        leading: Icon(
                          Icons.drag_indicator,
                          color: isGeneral 
                              ? Theme.of(context).disabledColor 
                              : Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          category,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: isGeneral 
                                ? Theme.of(context).disabledColor 
                                : null,
                          ),
                        ),
                        trailing: isGeneral
                            ? const SizedBox(width: 48)
                            : IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Kategoriyi Sil'),
                                      content: Text(
                                        '$category kategorisini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz ve kategorideki tüm işlemler silinecektir.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('İptal'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            budgetProvider.deleteCategory(category);
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('$category kategorisi silindi'),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Sil',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Kapat',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 