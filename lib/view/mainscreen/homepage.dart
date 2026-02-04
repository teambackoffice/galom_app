import 'package:flutter/material.dart';
import 'package:location_tracker_app/view/bottom_nav/bottom_nav.dart';
import 'package:location_tracker_app/view/mainscreen/invoice/invoice.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/location_track.dart';
import 'package:location_tracker_app/view/mainscreen/profile_page/profile_page.dart';
import 'package:location_tracker_app/view/mainscreen/sales_order/sales_order.dart';
import 'package:location_tracker_app/view/mainscreen/tasks/tasks.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    LocationTrackingPage(),
    SalesOrdersListPage(),
    EmployeeTasks(),
    InvoicePage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            left: 16,
            right: 16,
            bottom: 10, // Adjust this value to move it higher/lower
            child: ModernBottomNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: const Color(0xFF667EEA),
              unselectedItemColor: Colors.grey[600],
              backgroundColor: const Color(0xFFF5F5F7),
            ),
          ),
        ],
      ),
    );
  }
}
