import 'package:flutter/material.dart';
import 'package:billing_software/screens/splash_screen.dart';
import 'package:billing_software/services/theme_provider.dart';
import 'package:billing_software/services/shortcut_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  shortcutService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: shortcutService.navigatorKey,
          navigatorObservers: [shortcutService.routeObserver],
          debugShowCheckedModeBanner: false,
          title: 'Billing Software',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Colors.white,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
