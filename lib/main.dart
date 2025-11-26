import 'package:flutter/material.dart';
import 'injection.dart';
import 'core/themes/app_theme.dart';
import 'core/screens/main_navigation_screen.dart';

void main() {
  // Asegurar que los bindings de Flutter estén inicializados
  // Necesario para usar servicios como path_provider antes de runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar inyección de dependencias antes de iniciar la app
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detección Vial - IA',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
