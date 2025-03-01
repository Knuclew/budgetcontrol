import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/pdf_preview.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        final categoryData = budgetProvider.categoryData[budgetProvider.selectedCategory];
        final transactions = categoryData?.transactions ?? [];
        final spots = budgetProvider.getLastWeekData(budgetProvider.selectedCategory);
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bütçe Yöneticisi'),
            actions: [
              IconButton(
                icon: Icon(
                  budgetProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => budgetProvider.toggleTheme(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Kategori seçici
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: budgetProvider.categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == budgetProvider.categories.length) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text('Yeni'),
                          onPressed: () => _showAddCategoryDialog(context),
                        ),
                      );
                    }

                    final category = budgetProvider.categories[index];
                    final isSelected = category == budgetProvider.selectedCategory;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            budgetProvider.setSelectedCategory(category);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Bakiye kartları
              SizedBox(
                height: isSmallScreen ? 120 : 100,
                child: ListView(
                  scrollDirection: isSmallScreen ? Axis.horizontal : Axis.vertical,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 0,
                    vertical: isSmallScreen ? 0 : 8,
                  ),
                  children: [
                    _BalanceCard(
                      title: 'Gelir',
                      amount: categoryData?.balances['Gelir'] ?? 0,
                      color: Colors.green,
                      icon: Icons.arrow_upward,
                      width: isSmallScreen ? 150 : (screenWidth - 32),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 0, height: isSmallScreen ? 0 : 8),
                    _BalanceCard(
                      title: 'Gider',
                      amount: categoryData?.balances['Gider'] ?? 0,
                      color: Colors.red,
                      icon: Icons.arrow_downward,
                      width: isSmallScreen ? 150 : (screenWidth - 32),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 0, height: isSmallScreen ? 0 : 8),
                    _BalanceCard(
                      title: 'Net',
                      amount: (categoryData?.balances['Gelir'] ?? 0) - 
                              (categoryData?.balances['Gider'] ?? 0),
                      color: Colors.blue,
                      icon: Icons.account_balance,
                      width: isSmallScreen ? 150 : (screenWidth - 32),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 0, height: isSmallScreen ? 0 : 8),
                    _BalanceCard(
                      title: 'Tasarruf',
                      amount: categoryData?.balances['Tasarruf'] ?? 0,
                      color: Colors.purple,
                      icon: Icons.savings,
                      width: isSmallScreen ? 150 : (screenWidth - 32),
                    ),
                  ],
                ),
              ),

              // Grafik
              if (spots.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Son 7 Günlük Özet'),
                ),
                SizedBox(
                  height: isSmallScreen ? 200 : 250,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1000,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Theme.of(context).dividerColor.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1000,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()} ₺',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= spots.length) {
                                  return const Text('');
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('dd/MM').format(spots[value.toInt()].date),
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots.map((spot) => FlSpot(spot.x, spot.y)).toList(),
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: isSmallScreen ? 4 : 5,
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeWidth: 2,
                                  strokeColor: Theme.of(context).colorScheme.surface,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  Theme.of(context).colorScheme.primary.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        minY: spots.isEmpty ? 0 : null,
                        maxY: spots.isEmpty ? 1000 : null,
                      ),
                    ),
                  ),
                ),
              ],

              // İşlem butonları
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : screenWidth * 0.1,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Gelir Ekle',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        onPressed: () => _showTransactionDialog(context, 'Gelir'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.remove),
                        label: Text(
                          'Gider Ekle',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        onPressed: () => _showTransactionDialog(context, 'Gider'),
                      ),
                    ),
                  ],
                ),
              ),

              // İşlem geçmişi
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Text('Henüz işlem bulunmuyor'),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : screenWidth * 0.1,
                          vertical: 16,
                        ),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return Hero(
                            tag: 'transaction-${transaction.date.toIso8601String()}',
                            child: Dismissible(
                              key: Key(transaction.date.toIso8601String()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                color: Colors.red,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                context.read<BudgetProvider>().deleteTransaction(transaction);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('İşlem silindi'),
                                    action: SnackBarAction(
                                      label: 'Geri Al',
                                      onPressed: () {
                                        context.read<BudgetProvider>().addTransaction(
                                          category: transaction.category,
                                          type: transaction.type,
                                          subCategory: transaction.subCategory,
                                          amount: transaction.amount,
                                          note: transaction.note,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                child: ListTile(
                                  leading: Icon(
                                    transaction.type == 'Gelir' 
                                        ? Icons.add_circle 
                                        : Icons.remove_circle,
                                    color: transaction.type == 'Gelir' 
                                        ? Colors.green 
                                        : Colors.red,
                                    size: isSmallScreen ? 24 : 28,
                                  ),
                                  title: Text(
                                    transaction.subCategory,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                      if (transaction.note != null)
                                        Text(
                                          transaction.note!,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '${transaction.type == 'Gelir' ? '+' : '-'}${transaction.amount} ₺',
                                    style: TextStyle(
                                      color: transaction.type == 'Gelir' 
                                          ? Colors.green 
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: isSmallScreen ? 32 : screenWidth * 0.1),
                child: FloatingActionButton(
                  heroTag: 'clearButton',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Kategoriyi Temizle'),
                        content: Text('${budgetProvider.selectedCategory} kategorisindeki tüm işlemler silinecek. Emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<BudgetProvider>().clearCategory(budgetProvider.selectedCategory);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tüm işlemler silindi'),
                                ),
                              );
                            },
                            child: const Text('Temizle'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  backgroundColor: Colors.red,
                  child: Icon(
                    Icons.delete_forever,
                    size: isSmallScreen ? 24 : 28,
                  ),
                ),
              ),
              FloatingActionButton(
                heroTag: 'printButton',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFPreviewPage(
                        category: budgetProvider.selectedCategory,
                        transactions: transactions,
                        balances: categoryData?.balances ?? {},
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.print,
                  size: isSmallScreen ? 24 : 28,
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Yeni Kategori'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Kategori Adı',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  context.read<BudgetProvider>().addCategory(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => TransactionDialog(type: type),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final double width;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const Spacer(),
            Text(
              // Net bakiye için özel format, diğerleri için normal format
              title == 'Net' 
                  ? '${amount < 0 ? '-' : ''}${amount.abs()} ₺'
                  : '${amount.abs()} ₺',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: title == 'Net' && amount < 0 ? Colors.red : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 