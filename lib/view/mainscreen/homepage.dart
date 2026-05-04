import 'package:flutter/material.dart';
import 'package:location_tracker_app/view/mainscreen/invoice/invoice.dart';
import 'package:location_tracker_app/view/mainscreen/leave/leave_application.dart';
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
    InvoicePage(),
    LeaveApplication(),

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
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF667EEA),
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          iconSize: 24,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_center_rounded),
              label: 'Sales',
            ),
            // BottomNavigationBarItem(icon: Icon(Icons.add_task), label: 'Tasks'),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: 'Invoice',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Leave',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
