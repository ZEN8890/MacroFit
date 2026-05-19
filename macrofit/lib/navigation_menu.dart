import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/history_page.dart';
import 'pages/restaurant_page.dart';
import 'pages/forum_page.dart'; // 1. IMPORT HALAMAN FORUM BARU

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi saat layar digeser
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fungsi saat ikon navbar diklik
  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          HomePage(), // Index 0
          HistoryPage(), // Index 1
          RestaurantPage(), // Index 2
          ForumPage(), // 2. TAMBAHKAN FORUM PAGE DI INDEX 3
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Restoran',
          ),
          // --- 3. TAMBAHKAN ITEM NAVIGASI FORUM (ALA THREADS) ---
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Forum',
          ),
        ],
      ),
    );
  }
}
