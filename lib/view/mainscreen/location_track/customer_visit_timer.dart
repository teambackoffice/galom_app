import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/employee_location_controller.dart';
import 'package:provider/provider.dart';

class CustomerVisitTimerPage extends StatefulWidget {
  const CustomerVisitTimerPage({super.key});

  @override
  State<CustomerVisitTimerPage> createState() => _CustomerVisitTimerPageState();
}

class _CustomerVisitTimerPageState extends State<CustomerVisitTimerPage> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isVisitActive = false;
  String? _customerName;
  String? _visitPurpose;
  DateTime? _checkInTime;

  final _customerController = TextEditingController();
  final _purposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActiveVisit();
  }

  void _loadActiveVisit() {
    final controller = Provider.of<LocationController>(context, listen: false);
    final activeVisit = controller.activeCustomerVisit;

    if (activeVisit != null) {
      setState(() {
        _isVisitActive = true;
        _customerName = activeVisit['customer_name'];
        _visitPurpose = activeVisit['purpose'];
        _checkInTime = activeVisit['check_in_time'];
        _elapsed = DateTime.now().difference(_checkInTime!);
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && _isVisitActive) {
        setState(() {
          _elapsed = DateTime.now().difference(_checkInTime!);
        });
      }
    });
  }

  void _checkInToCustomer() async {
    if (_customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter customer name'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final controller = Provider.of<LocationController>(context, listen: false);

    final success = await controller.checkInToCustomer(
      customerName: _customerController.text.trim(),
      purpose: _purposeController.text.trim(),
    );

    if (success) {
      setState(() {
        _isVisitActive = true;
        _customerName = _customerController.text.trim();
        _visitPurpose = _purposeController.text.trim();
        _checkInTime = DateTime.now();
        _elapsed = Duration.zero;
      });
      _startTimer();
      _customerController.clear();
      _purposeController.clear();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Checked in to $_customerName')),
            ],
          ),
          backgroundColor: Colors.green.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check in'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _checkOutFromCustomer() async {
    final controller = Provider.of<LocationController>(context, listen: false);

    final success = await controller.checkOutFromCustomer();

    if (success) {
      final visitDuration = _formatDuration(_elapsed);
      final customer = _customerName;

      setState(() {
        _isVisitActive = false;
        _customerName = null;
        _visitPurpose = null;
        _checkInTime = null;
        _elapsed = Duration.zero;
      });
      _timer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.schedule, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Checked out from $customer • $visitDuration'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF764ba2),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check out'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showCheckInDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.all(24),
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_add, color: Colors.white, size: 32),
              ),
              SizedBox(height: 16),
              Text(
                'Check In to Customer',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customerController,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  hintText: 'Enter customer name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _purposeController,
                decoration: InputDecoration(
                  labelText: 'Purpose (Optional)',
                  hintText: 'Visit purpose',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.notes),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _customerController.clear();
                _purposeController.clear();
                Navigator.pop(context);
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _checkInToCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF764ba2),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Check In'),
            ),
          ],
        );
      },
    );
  }

  void _showCheckOutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.all(24),
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  color: Colors.orange.shade700,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Confirm Check Out',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Color(0xFF764ba2)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _customerName ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_visitPurpose?.isNotEmpty ?? false) ...[
                      SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _visitPurpose!,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _formatDuration(_elapsed),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _checkOutFromCustomer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Check Out'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _customerController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isVisitActive
                ? [Color(0xFF667eea), Color(0xFF764ba2)]
                : [Color(0xFF74b9ff), Color(0xFF667eea)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Customer Visit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isVisitActive) ...[
                          // Active Visit Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Icon
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_pin,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),

                                SizedBox(height: 24),

                                // Customer Name
                                Text(
                                  _customerName ?? '',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                if (_visitPurpose?.isNotEmpty ?? false) ...[
                                  SizedBox(height: 12),
                                  Text(
                                    _visitPurpose!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],

                                SizedBox(height: 32),

                                // Timer
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 25,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'VISIT DURATION',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _formatDuration(_elapsed),
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Check-in Time
                                Text(
                                  'Started at ${_checkInTime != null ? DateFormat("hh:mm a").format(_checkInTime!) : ""}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 40),

                          // Check Out Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showCheckOutDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF764ba2),
                                padding: EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Check Out',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // No Active Visit
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_off_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  'No Active Visit',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Check in to a customer to start\ntracking your visit time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 40),

                          // Check In Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showCheckInDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF764ba2),
                                padding: EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Check In to Customer',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
