import 'package:flutter/material.dart';
import 'package:location_tracker_app/controller/employee_location_controller.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/customer_visit_log.dart';
import 'package:location_tracker_app/view/mainscreen/location_track/customer_visit_timer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class LocationTrackingPage extends StatefulWidget {
  const LocationTrackingPage({super.key});

  @override
  _LocationTrackingPageState createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late LocationController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = Provider.of<LocationController>(
      context,
      listen: false,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startTracking() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(children: [SizedBox(width: 8), Text("Check - In ?")]),
          content: Text(
            " Are you sure you want to check - in?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _locationController.startTracking();
                if (_locationController.isTracking) {
                  _pulseController.repeat(reverse: true);
                  _rotationController.repeat();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Yes, Check - In",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _stopTracking() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(children: [SizedBox(width: 8), Text("Check - Out ?")]),
          content: Text(
            " Are you sure you want to check - out?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _locationController.stopTracking();
                _pulseController.stop();
                _rotationController.stop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Yes, Check - Out",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    int selectedInterval = _locationController.trackingInterval;
    bool batchEnabled = _locationController.enableBatchSending;
    int batchSize = _locationController.batchSize;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Automatic Tracking Settings"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Interval Setting
                    Text(
                      "Auto Update Interval:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    DropdownButton<int>(
                      value: selectedInterval,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 30, child: Text("30 seconds")),
                        DropdownMenuItem(value: 60, child: Text("1 minute")),
                        DropdownMenuItem(value: 120, child: Text("2 minutes")),
                        DropdownMenuItem(value: 300, child: Text("5 minutes")),
                        DropdownMenuItem(value: 600, child: Text("10 minutes")),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedInterval = value!;
                        });
                      },
                    ),

                    SizedBox(height: 20),
                    Divider(),

                    // Batch Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Batch Sending:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: batchEnabled,
                          onChanged: (value) {
                            setDialogState(() {
                              batchEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),

                    if (batchEnabled) ...[
                      SizedBox(height: 10),
                      Text(
                        "Batch Size:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      DropdownButton<int>(
                        value: batchSize,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 5,
                            child: Text("5 locations per batch"),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child: Text("10 locations per batch"),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text("15 locations per batch"),
                          ),
                          DropdownMenuItem(
                            value: 20,
                            child: Text("20 locations per batch"),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            batchSize = value!;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Batch mode reduces network requests and saves battery by sending multiple locations at once.",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ] else ...[
                      SizedBox(height: 10),
                      Text(
                        "Each location will be sent immediately to the server every $selectedInterval seconds.",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _locationController.updateTrackingInterval(
                      selectedInterval,
                    );
                    _locationController.toggleBatchSending(batchEnabled);
                    _locationController.updateBatchSize(batchSize);
                    Navigator.pop(context);
                  },
                  child: Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationController>(
      builder: (context, controller, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: controller.isTracking
                    ? [Color(0xFF667eea), Color(0xFF764ba2)]
                    : [Color(0xFF74b9ff), Color(0xFF0984e3)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(controller),
                  SizedBox(height: 100),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          SizedBox(height: 20), // Add some top spacing
                          // Animated tracking indicator
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              if (controller.isTracking)
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  controller.isTracking
                                      ? Icons.gps_fixed
                                      : Icons.gps_not_fixed,
                                  size: 50,
                                  color: controller.isTracking
                                      ? Color(0xFF00b894)
                                      : Color(0xFF636e72),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 100),

                          // Status container
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              controller.isTracking
                                  ? "You are Check - In"
                                  : " You are Check - Out",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(height: 20),

                          // Tracking details
                          if (controller.isTracking)
                            Column(
                              children: [
                                if (controller.hasPendingEntries) ...[
                                  SizedBox(height: 10),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.queue,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "${controller.pendingEntriesCount} pending",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              controller.sendPendingEntries(),
                                          child: Icon(
                                            Icons.send,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                          SizedBox(height: 20),

                          // Status messages
                          if (controller.lastResult != null)
                            if (controller.error != null) ...[
                              SizedBox(height: 10),
                            ],

                          SizedBox(height: 40),

                          // Main tracking button
                          GestureDetector(
                            onTap: controller.isLoading
                                ? null
                                : (controller.isTracking
                                      ? _stopTracking
                                      : _startTracking),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              width: 280,
                              height: 65,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: controller.isTracking
                                      ? [Color(0xFFff7675), Color(0xFFd63031)]
                                      : [Color(0xFF00b894), Color(0xFF00a085)],
                                ),
                                borderRadius: BorderRadius.circular(35),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (controller.isTracking
                                                ? Color(0xFFff7675)
                                                : Color(0xFF00b894))
                                            .withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (controller.isLoading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      controller.isTracking
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  SizedBox(width: 12),
                                  Text(
                                    controller.isLoading
                                        ? 'Please wait...'
                                        : (controller.isTracking
                                              ? 'Check - Out'
                                              : 'Check - In'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 20),

                          // Show "Open Settings" button if there's a permission error
                          if (controller.error != null &&
                              controller.error!.contains('Settings'))
                            GestureDetector(
                              onTap: () async {
                                await Permission.location.request();
                                // Try to open app settings
                                final opened = await openAppSettings();
                                if (opened) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please enable location permission and return to the app',
                                      ),
                                      backgroundColor: Colors.blue,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 280,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Open Settings',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Show error message
                          if (controller.error != null)
                            Container(
                              margin: EdgeInsets.only(top: 20),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      controller.error!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: 30),

                          // Action buttons row

                          // Add bottom spacing for scrolling
                          SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(LocationController controller) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF764BA2).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee Attendance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'visit_log':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerVisitLogger(),
                    ),
                  );
                  break;
                case 'customer_timer': // ✅ ADD THIS CASE
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerVisitTimerPage(),
                    ),
                  );
                  break;
                case 'send_pending':
                  controller.sendPendingEntries();
                  break;
                case 'clear_error':
                  controller.error = null;
                  controller.notifyListeners();
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'visit_log',
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Customer Visit Log'),
                    ],
                  ),
                ),
                // ✅ ADD THIS NEW MENU ITEM
                PopupMenuItem(
                  value: 'customer_timer',
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Customer Visit Timer'),
                    ],
                  ),
                ),
                // Show active visit indicator if there's an active visit
                if (controller.hasActiveCustomerVisit)
                  PopupMenuItem(
                    enabled: false, // Just a visual indicator, not clickable
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Active Visit',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (controller.hasPendingEntries)
                  PopupMenuItem(
                    value: 'send_pending',
                    child: Row(
                      children: [
                        Icon(Icons.send, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Send Pending (${controller.pendingEntriesCount})',
                        ),
                      ],
                    ),
                  ),
                if (controller.error != null)
                  PopupMenuItem(
                    value: 'clear_error',
                    child: Row(
                      children: [
                        Icon(Icons.clear, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear Error'),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

// import 'dart:io';

// import 'package:another_flushbar/flushbar.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';

// class VehicleCheckInScreen extends StatefulWidget {
//   const VehicleCheckInScreen({super.key});

//   @override
//   _VehicleCheckInScreenState createState() => _VehicleCheckInScreenState();
// }

// class _VehicleCheckInScreenState extends State<VehicleCheckInScreen> {
//   final ImagePicker _picker = ImagePicker();

//   bool isCheckedIn = false;
//   String? checkInTime;
//   String? checkInKm;
//   File? checkInImage;
//   String? checkOutTime;
//   String? checkOutKm;
//   File? checkOutImage;

//   // Location data (dummy for now)
//   String currentLocation = "Loading...";
//   double? latitude;
//   double? longitude;

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   Future<void> _getCurrentLocation() async {
//     // Simulate getting location
//     await Future.delayed(Duration(seconds: 1));
//     if (mounted) {
//       setState(() {
//         currentLocation = "123 Main Street, City, State";
//         latitude = 12.9716;
//         longitude = 77.5946;
//       });
//     }
//   }

//   // Show check-in/checkout dialog
//   void _showCheckInDialog() {
//     final TextEditingController kmController = TextEditingController();
//     File? tempImage;
//     bool isLoading = false;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Container(
//                 constraints: BoxConstraints(maxWidth: 400),
//                 padding: EdgeInsets.all(24),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Header
//                       Container(
//                         width: 70,
//                         height: 70,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: isCheckedIn
//                                 ? [Colors.orange.shade400, Colors.red.shade500]
//                                 : [Color(0xFF667EEA), Color(0xFF764BA2)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color:
//                                   (isCheckedIn
//                                           ? Colors.orange
//                                           : Color(0xFF764BA2))
//                                       .withOpacity(0.3),
//                               blurRadius: 12,
//                               offset: Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Icon(
//                           isCheckedIn
//                               ? Icons.logout_rounded
//                               : Icons.login_rounded,
//                           color: Colors.white,
//                           size: 36,
//                         ),
//                       ),

//                       SizedBox(height: 20),

//                       Text(
//                         isCheckedIn ? 'Check Out' : 'Check In',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF2D3436),
//                         ),
//                       ),

//                       SizedBox(height: 8),

//                       Text(
//                         isCheckedIn
//                             ? 'Enter your checkout details'
//                             : 'Enter your check-in details',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey.shade600,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),

//                       SizedBox(height: 24),

//                       // KM Input Field
//                       TextField(
//                         controller: kmController,
//                         keyboardType: TextInputType.numberWithOptions(
//                           decimal: true,
//                         ),
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         decoration: InputDecoration(
//                           labelText: 'Odometer Reading',
//                           hintText: 'Enter KM',
//                           prefixIcon: Icon(
//                             Icons.speed_rounded,
//                             color: Color(0xFF764BA2),
//                           ),
//                           suffixText: 'KM',
//                           suffixStyle: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF764BA2),
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(
//                               color: Color(0xFF764BA2),
//                               width: 2,
//                             ),
//                           ),
//                           filled: true,
//                           fillColor: Colors.grey.shade50,
//                         ),
//                         inputFormatters: [
//                           FilteringTextInputFormatter.allow(
//                             RegExp(r'^\d+\.?\d{0,2}'),
//                           ),
//                         ],
//                       ),

//                       SizedBox(height: 20),

//                       // Image Capture Section
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade50,
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.grey.shade300),
//                         ),
//                         child: Column(
//                           children: [
//                             if (tempImage == null)
//                               InkWell(
//                                 onTap: () => _showImageSourceOptions(
//                                   setDialogState,
//                                   (image) {
//                                     setDialogState(() {
//                                       tempImage = image;
//                                     });
//                                   },
//                                 ),
//                                 child: Container(
//                                   height: 160,
//                                   decoration: BoxDecoration(
//                                     color: Color(0xFF764BA2).withOpacity(0.05),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Center(
//                                     child: Column(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         Icon(
//                                           Icons.add_a_photo_rounded,
//                                           size: 48,
//                                           color: Color(0xFF764BA2),
//                                         ),
//                                         SizedBox(height: 12),
//                                         Text(
//                                           'Capture Odometer Photo',
//                                           style: TextStyle(
//                                             fontSize: 15,
//                                             fontWeight: FontWeight.w600,
//                                             color: Color(0xFF2D3436),
//                                           ),
//                                         ),
//                                         SizedBox(height: 4),
//                                         Text(
//                                           'Tap to take photo',
//                                           style: TextStyle(
//                                             fontSize: 12,
//                                             color: Colors.grey.shade600,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             else
//                               Stack(
//                                 children: [
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(12),
//                                     child: Image.file(
//                                       tempImage!,
//                                       height: 200,
//                                       width: double.infinity,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ),
//                                   Positioned(
//                                     top: 8,
//                                     right: 8,
//                                     child: Row(
//                                       children: [
//                                         Container(
//                                           decoration: BoxDecoration(
//                                             color: Colors.green.shade600,
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: IconButton(
//                                             icon: Icon(
//                                               Icons.check_circle,
//                                               color: Colors.white,
//                                             ),
//                                             onPressed: null,
//                                           ),
//                                         ),
//                                         SizedBox(width: 8),
//                                         Container(
//                                           decoration: BoxDecoration(
//                                             color: Colors.red.shade600,
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: IconButton(
//                                             icon: Icon(
//                                               Icons.close,
//                                               color: Colors.white,
//                                             ),
//                                             onPressed: () {
//                                               setDialogState(() {
//                                                 tempImage = null;
//                                               });
//                                             },
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                           ],
//                         ),
//                       ),

//                       SizedBox(height: 24),

//                       // Action Buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton(
//                               onPressed: isLoading
//                                   ? null
//                                   : () => Navigator.pop(context),
//                               style: OutlinedButton.styleFrom(
//                                 padding: EdgeInsets.symmetric(vertical: 14),
//                                 side: BorderSide(
//                                   color: Colors.grey.shade400,
//                                   width: 1.5,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child: Text(
//                                 'Cancel',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.grey.shade700,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: ElevatedButton(
//                               onPressed: isLoading
//                                   ? null
//                                   : () async {
//                                       // Validate
//                                       if (kmController.text.isEmpty) {
//                                         _showErrorMessage(
//                                           'Please enter KM reading',
//                                         );
//                                         return;
//                                       }

//                                       if (tempImage == null) {
//                                         _showErrorMessage(
//                                           'Please capture odometer photo',
//                                         );
//                                         return;
//                                       }

//                                       // Validate checkout KM
//                                       if (isCheckedIn && checkInKm != null) {
//                                         double currentKm = double.parse(
//                                           kmController.text,
//                                         );
//                                         double previousKm = double.parse(
//                                           checkInKm!,
//                                         );
//                                         if (currentKm <= previousKm) {
//                                           _showErrorMessage(
//                                             'Checkout KM must be greater than check-in KM',
//                                           );
//                                           return;
//                                         }
//                                       }

//                                       setDialogState(() {
//                                         isLoading = true;
//                                       });

//                                       // Simulate API call
//                                       await Future.delayed(
//                                         Duration(seconds: 2),
//                                       );

//                                       if (isCheckedIn) {
//                                         // Checkout
//                                         setState(() {
//                                           checkOutTime = DateFormat(
//                                             'hh:mm a',
//                                           ).format(DateTime.now());
//                                           checkOutKm = kmController.text;
//                                           checkOutImage = tempImage;
//                                         });

//                                         Navigator.pop(context);
//                                         _showCheckoutSummary();
//                                       } else {
//                                         // Check in
//                                         setState(() {
//                                           isCheckedIn = true;
//                                           checkInTime = DateFormat(
//                                             'hh:mm a',
//                                           ).format(DateTime.now());
//                                           checkInKm = kmController.text;
//                                           checkInImage = tempImage;
//                                         });

//                                         Navigator.pop(context);

//                                         Flushbar(
//                                           messageText: Text(
//                                             '✅ Checked in successfully!',
//                                             style: const TextStyle(
//                                               fontSize: 12,
//                                               fontWeight: FontWeight.w600,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                           backgroundColor:
//                                               Colors.green.shade500,
//                                           icon: const Icon(
//                                             Icons.check_circle,
//                                             color: Colors.white,
//                                           ),
//                                           margin: const EdgeInsets.all(12),
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                           duration: const Duration(seconds: 3),
//                                           flushbarPosition:
//                                               FlushbarPosition.TOP,
//                                           animationDuration: const Duration(
//                                             milliseconds: 400,
//                                           ),
//                                         ).show(context);
//                                       }
//                                     },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: isCheckedIn
//                                     ? Colors.red.shade600
//                                     : Color(0xFF764BA2),
//                                 foregroundColor: Colors.white,
//                                 padding: EdgeInsets.symmetric(vertical: 14),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 elevation: 2,
//                               ),
//                               child: isLoading
//                                   ? SizedBox(
//                                       height: 20,
//                                       width: 20,
//                                       child: CircularProgressIndicator(
//                                         color: Colors.white,
//                                         strokeWidth: 2.5,
//                                       ),
//                                     )
//                                   : Text(
//                                       isCheckedIn ? 'Check Out' : 'Check In',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w700,
//                                       ),
//                                     ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   void _showImageSourceOptions(
//     StateSetter setDialogState,
//     Function(File?) onImageSelected,
//   ) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Text(
//                   'Capture Odometer Reading',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2D3436),
//                   ),
//                 ),
//                 SizedBox(height: 20),

//                 // Camera option
//                 InkWell(
//                   onTap: () async {
//                     Navigator.pop(context);
//                     final image = await _captureImage(ImageSource.camera);
//                     if (image != null) {
//                       onImageSelected(image);
//                     }
//                   },
//                   child: Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Color(0xFF764BA2).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: Color(0xFF764BA2).withOpacity(0.3),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Color(0xFF764BA2),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Icon(
//                             Icons.camera_alt_rounded,
//                             color: Colors.white,
//                             size: 24,
//                           ),
//                         ),
//                         SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Take Photo',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xFF2D3436),
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 'Capture odometer directly',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Icon(
//                           Icons.arrow_forward_ios_rounded,
//                           size: 16,
//                           color: Color(0xFF764BA2),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 SizedBox(height: 12),

//                 // Gallery option
//                 InkWell(
//                   onTap: () async {
//                     Navigator.pop(context);
//                     final image = await _captureImage(ImageSource.gallery);
//                     if (image != null) {
//                       onImageSelected(image);
//                     }
//                   },
//                   child: Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.blue.shade200),
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade600,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Icon(
//                             Icons.photo_library_rounded,
//                             color: Colors.white,
//                             size: 24,
//                           ),
//                         ),
//                         SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Choose from Gallery',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xFF2D3436),
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 'Select existing photo',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Icon(
//                           Icons.arrow_forward_ios_rounded,
//                           size: 16,
//                           color: Colors.blue.shade600,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 SizedBox(height: 12),

//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text(
//                     'Cancel',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<File?> _captureImage(ImageSource source) async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: source,
//         imageQuality: 80,
//         preferredCameraDevice: CameraDevice.rear,
//       );

//       if (image != null) {
//         return File(image.path);
//       }
//       return null;
//     } catch (e) {
//       _showErrorMessage('Failed to capture image: $e');
//       return null;
//     }
//   }

//   void _showErrorMessage(String message) {
//     Flushbar(
//       messageText: Text(
//         message,
//         style: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//         ),
//       ),
//       backgroundColor: Colors.red.shade500,
//       icon: const Icon(Icons.error, color: Colors.white),
//       margin: const EdgeInsets.all(12),
//       borderRadius: BorderRadius.circular(12),
//       duration: const Duration(seconds: 3),
//       flushbarPosition: FlushbarPosition.TOP,
//       animationDuration: const Duration(milliseconds: 400),
//     ).show(context);
//   }

//   void _showCheckoutSummary() {
//     double distance = double.parse(checkOutKm!) - double.parse(checkInKm!);

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Container(
//           padding: EdgeInsets.all(24),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Success icon
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.green.shade400, Colors.green.shade600],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.green.withOpacity(0.3),
//                         blurRadius: 12,
//                         offset: Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: Icon(
//                     Icons.check_circle_outline_rounded,
//                     color: Colors.white,
//                     size: 50,
//                   ),
//                 ),

//                 SizedBox(height: 20),

//                 Text(
//                   'Check-Out Successful!',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF2D3436),
//                   ),
//                 ),

//                 SizedBox(height: 8),

//                 Text(
//                   'Your trip has been recorded',
//                   style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                 ),

//                 SizedBox(height: 24),

//                 // Summary card
//                 Container(
//                   padding: EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Color(0xFF667EEA).withOpacity(0.1),
//                         Color(0xFF764BA2).withOpacity(0.1),
//                       ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: Color(0xFF764BA2).withOpacity(0.2),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       _buildSummaryRow(
//                         'Check-In Time',
//                         checkInTime ?? '--',
//                         Icons.login_rounded,
//                         Colors.blue,
//                       ),
//                       Divider(height: 24),
//                       _buildSummaryRow(
//                         'Check-Out Time',
//                         checkOutTime ?? '--',
//                         Icons.logout_rounded,
//                         Colors.orange,
//                       ),
//                       Divider(height: 24),
//                       _buildSummaryRow(
//                         'Start KM',
//                         '$checkInKm km',
//                         Icons.speed_rounded,
//                         Colors.green,
//                       ),
//                       Divider(height: 24),
//                       _buildSummaryRow(
//                         'End KM',
//                         '$checkOutKm km',
//                         Icons.speed_rounded,
//                         Colors.red,
//                       ),
//                       Divider(height: 24),
//                       Container(
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                             begin: Alignment.centerLeft,
//                             end: Alignment.centerRight,
//                           ),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               padding: EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Icon(
//                                 Icons.route_rounded,
//                                 color: Colors.white,
//                                 size: 20,
//                               ),
//                             ),
//                             SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Total Distance',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.white.withOpacity(0.9),
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                   Text(
//                                     '${distance.toStringAsFixed(2)} km',
//                                     style: TextStyle(
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 SizedBox(height: 24),

//                 // Images section
//                 if (checkInImage != null || checkOutImage != null) ...[
//                   Text(
//                     'Odometer Photos',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF2D3436),
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                   Row(
//                     children: [
//                       if (checkInImage != null)
//                         Expanded(
//                           child: Column(
//                             children: [
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.file(
//                                   checkInImage!,
//                                   height: 100,
//                                   width: double.infinity,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                               SizedBox(height: 6),
//                               Text(
//                                 'Check-In',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey.shade600,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       if (checkInImage != null && checkOutImage != null)
//                         SizedBox(width: 12),
//                       if (checkOutImage != null)
//                         Expanded(
//                           child: Column(
//                             children: [
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.file(
//                                   checkOutImage!,
//                                   height: 100,
//                                   width: double.infinity,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                               SizedBox(height: 6),
//                               Text(
//                                 'Check-Out',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey.shade600,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                   SizedBox(height: 20),
//                 ],

//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                       setState(() {
//                         isCheckedIn = false;
//                         checkInTime = null;
//                         checkInKm = null;
//                         checkInImage = null;
//                         checkOutTime = null;
//                         checkOutKm = null;
//                         checkOutImage = null;
//                       });
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF764BA2),
//                       foregroundColor: Colors.white,
//                       padding: EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 2,
//                     ),
//                     child: Text(
//                       'Done',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryRow(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Row(
//       children: [
//         Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: color, size: 20),
//         ),
//         SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey.shade600,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w700,
//                   color: Color(0xFF2D3436),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF8F6FA),
//       appBar: AppBar(
//         title: Text(
//           'Vehicle Check-In',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Color(0xFF764BA2),
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.white),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status Card
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Container(
//                 padding: EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: isCheckedIn
//                         ? [Colors.green.shade400, Colors.green.shade600]
//                         : [Color(0xFF667EEA), Color(0xFF764BA2)],
//                     begin: Alignment.centerLeft,
//                     end: Alignment.centerRight,
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Icon(
//                         isCheckedIn
//                             ? Icons.check_circle_outline_rounded
//                             : Icons.access_time_rounded,
//                         color: Colors.white,
//                         size: 32,
//                       ),
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             isCheckedIn ? 'Checked In' : 'Not Checked In',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.white,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             isCheckedIn
//                                 ? 'Started at $checkInTime'
//                                 : 'Tap below to start your shift',
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.white.withOpacity(0.9),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             SizedBox(height: 16),

//             // Location Card
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.location_on_rounded,
//                           color: Color(0xFF764BA2),
//                           size: 24,
//                         ),
//                         SizedBox(width: 8),
//                         Text(
//                           'Current Location',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF2D3436),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 12),
//                     Container(
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey.shade200),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.my_location_rounded,
//                             color: Colors.green.shade600,
//                             size: 20,
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   currentLocation,
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Color(0xFF2D3436),
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 if (latitude != null && longitude != null) ...[
//                                   SizedBox(height: 4),
//                                   Text(
//                                     'Lat: ${latitude!.toStringAsFixed(6)}, Long: ${longitude!.toStringAsFixed(6)}',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey.shade600,
//                                       fontFamily: 'monospace',
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Check-In Info Card (if checked in)
//             if (isCheckedIn) ...[
//               SizedBox(height: 16),
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Container(
//                   padding: EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.blue.shade200),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.info_outline_rounded,
//                             color: Colors.blue.shade700,
//                             size: 24,
//                           ),
//                           SizedBox(width: 8),
//                           Text(
//                             'Check-In Details',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.blue.shade900,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildInfoItem(
//                               'Time',
//                               checkInTime ?? '--',
//                               Icons.access_time_rounded,
//                             ),
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: _buildInfoItem(
//                               'KM Reading',
//                               '$checkInKm km',
//                               Icons.speed_rounded,
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (checkInImage != null) ...[
//                         SizedBox(height: 12),
//                         Text(
//                           'Odometer Photo:',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.blue.shade900,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.file(
//                             checkInImage!,
//                             height: 120,
//                             width: double.infinity,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ],

//             SizedBox(height: 24),

//             // Action Button
//             SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: _showCheckInDialog,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isCheckedIn
//                       ? Colors.red.shade600
//                       : Color(0xFF764BA2),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 3,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       isCheckedIn ? Icons.logout_rounded : Icons.login_rounded,
//                       size: 24,
//                     ),
//                     SizedBox(width: 12),
//                     Text(
//                       isCheckedIn ? 'Check Out Now' : 'Check In Now',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoItem(String label, String value, IconData icon) {
//     return Container(
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.blue.shade100),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 16, color: Colors.blue.shade700),
//               SizedBox(width: 6),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.grey.shade600,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w700,
//               color: Colors.blue.shade900,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
