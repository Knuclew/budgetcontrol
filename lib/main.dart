import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'providers/budget_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    runApp(BudgetManagerApp(prefs: prefs));
  } catch (e) {
    debugPrint('Başlatma hatası: $e');
    runApp(const BudgetManagerApp(prefs: null));
  }
}

class BudgetManagerApp extends StatelessWidget {
  final SharedPreferences? prefs;
  const BudgetManagerApp({super.key, this.prefs});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BudgetProvider(prefs: prefs),
      child: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, _) {
          return MaterialApp(
            title: 'Bütçe Yöneticisi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: budgetProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
