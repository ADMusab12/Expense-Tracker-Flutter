import 'package:expense_tracker/abstraction/database/database_service.dart';
import 'package:expense_tracker/abstraction/theme/theme_provider.dart';
import 'package:expense_tracker/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


final databaseService = DatabaseService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await databaseService.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( 
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>( 
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: "Expense Tracker",
            debugShowCheckedModeBanner: false,
            theme: _lightTheme, // Light theme
            darkTheme: _darkTheme, // Dark theme
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light, // Dynamic mode
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  static final ThemeData _lightTheme = ThemeData(
    primarySwatch: Colors.indigo,
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[50],
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    primarySwatch: Colors.indigo,
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[850],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
