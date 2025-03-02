import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BudgetProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Hesap kategorileri ve bakiyeleri
  final Map<String, CategoryData> _categoryData = {
    'Genel': CategoryData(
      balances: {'Gelir': 0, 'Gider': 0, 'Tasarruf': 0},
      transactions: [],
    ),
  };
  Map<String, CategoryData> get categoryData => _categoryData;
  List<String> get categories => _categoryData.keys.toList();

  // Alt başlıklar
  final Map<String, List<String>> _subCategories = {
    'Gelir': [
      'Maaş',
      'Ek Gelir',
      'Hediye',
      'Yatırım Geliri',
      'Kira Geliri',
      'Freelance',
      'Prim',
      'Diğer',
    ],
    'Gider': [
      'Kira/Mortgage',
      'Market',
      'Faturalar',
      'Ulaşım',
      'Sağlık',
      'Eğitim',
      'Eğlence',
      'Giyim',
      'Teknoloji',
      'Restoran',
      'Spor',
      'Bakım',
      'Sigorta',
      'Diğer',
    ],
    'Tasarruf': [
      'Birikim',
      'Yatırım',
      'Acil Durum Fonu',
      'Emeklilik',
      'Hedef Birikim',
      'Diğer',
    ],
  };
  Map<String, List<String>> get subCategories => _subCategories;

  // Seçili kategori
  String _selectedCategory = 'Genel';
  String get selectedCategory => _selectedCategory;

  BudgetProvider({SharedPreferences? prefs}) {
    _prefs = prefs;
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _loadData();
    } catch (e) {
      debugPrint('SharedPreferences hatası: $e');
      // Varsayılan değerleri kullan
      _isDarkMode = false;
      _selectedCategory = 'Genel';
      _categoryData.clear();
      _categoryData['Genel'] = CategoryData(
        balances: {'Gelir': 0, 'Gider': 0, 'Tasarruf': 0},
        transactions: [],
      );
    }
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs?.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  void addCategory(String category) {
    if (!_categoryData.containsKey(category)) {
      _categoryData[category] = CategoryData(
        balances: {'Gelir': 0, 'Gider': 0, 'Tasarruf': 0},
        transactions: [],
      );
      _saveData();
      notifyListeners();
    }
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addTransaction({
    required String category,
    required String type,
    required String subCategory,
    required double amount,
    String? note,
  }) {
    if (!_categoryData.containsKey(category)) {
      _categoryData[category] = CategoryData(
        balances: {'Gelir': 0, 'Gider': 0, 'Tasarruf': 0},
        transactions: [],
      );
    }

    final transaction = Transaction(
      category: category,
      type: type,
      subCategory: subCategory,
      amount: amount,
      note: note,
      date: DateTime.now(),
    );

    _categoryData[category]!.transactions.add(transaction);
    
    // Bakiyeleri güncelle
    if (type == 'Gider') {
      _categoryData[category]!.balances[type] = 
          (_categoryData[category]!.balances[type] ?? 0) + amount;
    } else {
      _categoryData[category]!.balances[type] = 
          (_categoryData[category]!.balances[type] ?? 0) + amount;
    }

    _saveData();
    notifyListeners();
  }

  void deleteTransaction(Transaction transaction) {
    if (_categoryData.containsKey(transaction.category)) {
      _categoryData[transaction.category]!.transactions.removeWhere(
        (t) => t.date == transaction.date && t.amount == transaction.amount,
      );

      // Bakiyeleri güncelle
      if (transaction.type == 'Gider') {
        _categoryData[transaction.category]!.balances[transaction.type] = 
            (_categoryData[transaction.category]!.balances[transaction.type] ?? 0) - transaction.amount;
      } else {
        _categoryData[transaction.category]!.balances[transaction.type] = 
            (_categoryData[transaction.category]!.balances[transaction.type] ?? 0) - transaction.amount;
      }

      _saveData();
      notifyListeners();
    }
  }

  void _recalculateBalances(String category) {
    if (_categoryData.containsKey(category)) {
      // Bakiyeleri sıfırla
      _categoryData[category]!.balances = {
        'Gelir': 0,
        'Gider': 0,
        'Tasarruf': 0,
      };

      // Tüm işlemleri tekrar hesapla
      for (var transaction in _categoryData[category]!.transactions) {
        _categoryData[category]!.balances[transaction.type] = 
            (_categoryData[category]!.balances[transaction.type] ?? 0) + transaction.amount;
      }
    }
  }

  List<Transaction> getTransactionsForCategory(String category) {
    return _categoryData[category]?.transactions ?? [];
  }

  double getBalanceForCategory(String category, String type) {
    return _categoryData[category]?.balances[type] ?? 0;
  }

  List<FlSpotData> getLastWeekData(String category) {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    
    final transactions = _categoryData[category]?.transactions ?? [];
    final Map<DateTime, double> dailyBalances = {};

    for (var i = 0; i < 7; i++) {
      final date = lastWeek.add(Duration(days: i));
      dailyBalances[DateTime(date.year, date.month, date.day)] = 0;
    }

    for (var transaction in transactions) {
      if (transaction.date.isAfter(lastWeek)) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        dailyBalances[date] = (dailyBalances[date] ?? 0) + 
            (transaction.type == 'Gider' ? -transaction.amount : transaction.amount);
      }
    }

    final spots = dailyBalances.entries
        .map((e) => FlSpotData(
              x: e.key.difference(lastWeek).inDays.toDouble(),
              y: e.value,
              date: e.key,
            ))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return spots;
  }

  void clearCategory(String category) {
    if (_categoryData.containsKey(category)) {
      _categoryData[category]!.transactions.clear();
      _categoryData[category]!.balances = {
        'Gelir': 0,
        'Gider': 0,
        'Tasarruf': 0,
      };
      _saveData();
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    try {
      await _prefs?.setBool('isDarkMode', _isDarkMode);
      await _prefs?.setString('selectedCategory', _selectedCategory);
      
      final Map<String, String> serializedData = {};
      for (var entry in _categoryData.entries) {
        serializedData[entry.key] = jsonEncode(entry.value.toJson());
      }
      
      await _prefs?.setString('categoryData', jsonEncode(serializedData));
    } catch (e) {
      debugPrint('Veri kaydetme hatası: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
      _selectedCategory = _prefs?.getString('selectedCategory') ?? 'Genel';
      
      final categoryDataString = _prefs?.getString('categoryData');
      if (categoryDataString != null) {
        final Map<String, dynamic> serializedData = 
            jsonDecode(categoryDataString) as Map<String, dynamic>;
        
        _categoryData.clear();
        for (var entry in serializedData.entries) {
          _categoryData[entry.key] = CategoryData.fromJson(
            jsonDecode(entry.value as String) as Map<String, dynamic>
          );
          // Yüklenen veriler için bakiyeleri yeniden hesapla
          _recalculateBalances(entry.key);
        }
      } else {
        // Varsayılan kategoriyi oluştur
        _categoryData['Genel'] = CategoryData(
          balances: {'Gelir': 0, 'Gider': 0, 'Tasarruf': 0},
          transactions: [],
        );
      }
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
      // Hata durumunda varsayılan değerleri kullan
      _isDarkMode = false;
      _selectedCategory = 'Genel';
      _categoryData.clear();
      _categoryData['Genel'] = CategoryData(
        balances: {'Gelir': 0, 'Gider': 0, 'Tasarruf': 0},
        transactions: [],
      );
    }
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<String> categoriesList = categories;
    final String item = categoriesList.removeAt(oldIndex);
    categoriesList.insert(newIndex, item);

    // Yeni sıralamaya göre Map'i güncelle
    final Map<String, CategoryData> newCategoryData = {};
    for (var category in categoriesList) {
      newCategoryData[category] = _categoryData[category]!;
    }
    _categoryData.clear();
    _categoryData.addAll(newCategoryData);
    
    _saveData();
    notifyListeners();
  }

  void deleteCategory(String category) {
    if (category == 'Genel') return; // Genel kategori silinemez
    if (_categoryData.containsKey(category)) {
      _categoryData.remove(category);
      if (_selectedCategory == category) {
        _selectedCategory = 'Genel';
      }
      _saveData();
      notifyListeners();
    }
  }
}

class CategoryData {
  Map<String, double> balances;
  final List<Transaction> transactions;

  CategoryData({
    required this.balances,
    required this.transactions,
  });

  Map<String, dynamic> toJson() => {
    'balances': balances,
    'transactions': transactions.map((t) => t.toJson()).toList(),
  };

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      balances: Map<String, double>.from(json['balances'] as Map),
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Transaction {
  final String category;
  final String type;
  final String subCategory;
  final double amount;
  final String? note;
  final DateTime date;

  Transaction({
    required this.category,
    required this.type,
    required this.subCategory,
    required this.amount,
    this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'type': type,
    'subCategory': subCategory,
    'amount': amount,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      category: json['category'] as String,
      type: json['type'] as String,
      subCategory: json['subCategory'] as String,
      amount: json['amount'] as double,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class FlSpotData {
  final double x;
  final double y;
  final DateTime date;

  FlSpotData({
    required this.x,
    required this.y,
    required this.date,
  });
} 