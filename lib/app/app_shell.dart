import 'package:flutter/material.dart';

import '../features/map/presentation/map_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/nearby/presentation/nearby_screen.dart';
import '../features/vehicle/presentation/vehicle_screen.dart';
import 'theme/app_colors.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _screens = [
    MapScreen(),
    NearbyScreen(),
    VehicleScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Cerca',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Mi coche',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'Más',
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
