/// Pantalla principal con navegación inferior
/// 
/// Gestiona la navegación entre las diferentes secciones de la aplicación
/// usando un BottomNavigationBar con Material Design 3.
library;

import 'package:flutter/material.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/storage/presentation/screens/storage_screen.dart';

/// Pantalla principal con navegación inferior
/// 
/// Esta pantalla contiene un BottomNavigationBar que permite navegar
/// entre las diferentes secciones de la aplicación:
/// - Inicio (Home)
/// - Mapa
/// - Historial
class MainNavigationScreen extends StatefulWidget {
  /// Constructor del MainNavigationScreen
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  /// Índice de la pestaña actual seleccionada
  int _currentIndex = 0;

  /// Lista de pantallas disponibles en la navegación
  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const StorageScreen(),
  ];

  /// Títulos de las pestañas
  final List<String> _titles = [
    'Inicio',
    'Mapa',
    'Historial',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
      ),
    );
  }
}

