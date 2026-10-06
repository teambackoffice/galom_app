import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location_tracker_app/controller/customer_list_controller.dart';
import 'package:location_tracker_app/controller/customer_log_visit_controller.dart';
import 'package:location_tracker_app/modal/customer_list_modal.dart';
import 'package:provider/provider.dart';

class CustomerVisitLogger extends StatefulWidget {
  const CustomerVisitLogger({super.key});

  @override
  _CustomerVisitLoggerState createState() => _CustomerVisitLoggerState();
}

class _CustomerVisitLoggerState extends State<CustomerVisitLogger> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _showSuccess = false;
  bool _isSubmitting = false;

  MessageElement? _selectedCustomer;
  List<MessageElement> _filteredCustomers = [];
  bool _showCustomerDropdown = false;

  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  DateTime? _capturedAt;
  bool _isPickingImage = false;
  bool _isLastCounter = false;

  @override
  void initState() {
    super.initState();
    // Fetch customer list when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GetCustomerListController>().fetchCustomerList();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _filterCustomers(String query, List<MessageElement> allCustomers) {
    if (query.isEmpty) {
      setState(() {
        _filteredCustomers = allCustomers;
        _showCustomerDropdown = allCustomers.isNotEmpty;
      });
      return;
    }

    final filtered = allCustomers.where((customer) {
      final nameLower = customer.customerName.toLowerCase();
      final queryLower = query.toLowerCase();
      final mobileMatch = customer.mobileNo?.contains(query) ?? false;
      final emailMatch =
          customer.emailId?.toLowerCase().contains(queryLower) ?? false;

      return nameLower.contains(queryLower) || mobileMatch || emailMatch;
    }).toList();

    setState(() {
      _filteredCustomers = filtered;
      _showCustomerDropdown = true; // Always show dropdown when typing
    });
  }

  void _selectCustomer(MessageElement customer) {
    setState(() {
      _selectedCustomer = customer;
      _customerNameController.text = customer.customerName;
      _showCustomerDropdown = false;
      _filteredCustomers = [];
    });
  }

  Future<void> _captureImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() {
          _capturedImage = File(picked.path);
          _capturedAt = DateTime.now();
          _showSuccess = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _logVisit() async {
    if (_isSubmitting) return;

    final controller = context.read<LogCustomerVisitController>();

    setState(() {
      _showSuccess = false;
      _isSubmitting = true;
    });

    if (_customerNameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both customer name and description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      Position position = await _getCurrentLocation();

      String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String time = DateFormat('HH:mm:ss').format(DateTime.now());

      await controller.logCustomerVisit(
        date: date,
        time: time,
        longitude: position.longitude,
        latitude: position.latitude,
        customerName:
            _selectedCustomer?.customerName ??
            _customerNameController.text.trim(),
        description: _descriptionController.text.trim(),
        photo: _capturedImage,
        isLastCounter: _isLastCounter,
      );

      if (controller.errorMessage == null) {
        setState(() => _showSuccess = true);
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Failed to log visit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _customerNameController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCustomer = null;
      _filteredCustomers = [];
      _showCustomerDropdown = false;
      _capturedImage = null;
      _capturedAt = null;
      _isLastCounter = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LogCustomerVisitController>();
    final customerListController = context.watch<GetCustomerListController>();

    final allCustomers =
        customerListController.customerlist?.message.message ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_outlined,
                color: Colors.black,
                size: 28,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 80),
            const Text(
              'Field Visit Logger',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 4,
      ),
      body: GestureDetector(
        onTap: () {
          // Hide dropdown when tapping outside
          setState(() => _showCustomerDropdown = false);
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_showSuccess)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.green,
                    child: const Row(
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Visit logged successfully!',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                if (_isSubmitting || controller.isLoading)
                  const LinearProgressIndicator(),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Customer Name *'),
                      const SizedBox(height: 8),

                      // Customer autocomplete field
                      Column(
                        children: [
                          _buildCustomerSearchField(
                            controller: _customerNameController,
                            allCustomers: allCustomers,
                            enabled: !_isSubmitting,
                            isLoading: customerListController.isLoading,
                          ),

                          // Dropdown overlay
                          if (_showCustomerDropdown)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _filteredCustomers.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'No customers found',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _filteredCustomers.length,
                                      itemBuilder: (context, index) {
                                        final customer =
                                            _filteredCustomers[index];
                                        return _buildCustomerListItem(customer);
                                      },
                                    ),
                            ),
                        ],
                      ),

                      if (_selectedCustomer != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected: ${_selectedCustomer!.customerName}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    if (_selectedCustomer!
                                            .mobileNo
                                            ?.isNotEmpty ??
                                        false)
                                      Text(
                                        _selectedCustomer!.mobileNo!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.blue[700],
                                onPressed: () {
                                  setState(() {
                                    _selectedCustomer = null;
                                    _customerNameController.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      _buildLabel('Visit Description *'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _descriptionController,
                        hint:
                            'Describe the purpose of visit, work done, or notes...',
                        maxLines: 4,
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[200], height: 1),
                      const SizedBox(height: 20),

                      _buildSectionHeader(
                        icon: Icons.photo_camera_outlined,
                        title: 'Visit Photo',
                        trailing: 'Optional',
                      ),
                      const SizedBox(height: 10),
                      _buildImageCapture(enabled: !_isSubmitting),
                      const SizedBox(height: 20),

                      _buildLastCounterSwitch(enabled: !_isSubmitting),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _logVisit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSubmitting
                                ? Colors.grey[400]
                                : Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: _isSubmitting ? 0 : 2,
                          ),
                          child: _isSubmitting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
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
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Logging Visit...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.check, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Log Visit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerListItem(MessageElement customer) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectCustomer(customer),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (customer.mobileNo?.isNotEmpty ?? false)
                      Text(
                        customer.mobileNo!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    if (customer.emailId?.isNotEmpty ?? false)
                      Text(
                        customer.emailId!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _selectCustomer(customer),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 1,
                minimumSize: const Size(70, 32),
              ),
              child: const Text(
                'Select',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          Text(
            trailing,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  Widget _buildImageCapture({required bool enabled}) {
    final canCapture = enabled && !_isPickingImage;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _capturedImage == null
          ? _buildCapturePlaceholder(canCapture: canCapture)
          : _buildCapturedPreview(enabled: enabled, canCapture: canCapture),
    );
  }

  Widget _buildCapturePlaceholder({required bool canCapture}) {
    return CustomPaint(
      key: const ValueKey('placeholder'),
      painter: _DashedBorderPainter(
        color: canCapture ? Colors.blue[300]! : Colors.grey[300]!,
      ),
      child: Material(
        color: canCapture
            ? Colors.blue[50]!.withValues(alpha: 0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: canCapture ? _captureImage : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 160,
            child: _isPickingImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Opening camera...',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: canCapture
                              ? Colors.blue[600]
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: canCapture
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Capture Visit Photo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: canCapture
                              ? Colors.blue[800]
                              : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take a clear photo of the counter or shop',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapturedPreview({
    required bool enabled,
    required bool canCapture,
  }) {
    return Container(
      key: const ValueKey('preview'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GestureDetector(
              onTap: _openImageViewer,
              child: Hero(
                tag: 'visit-photo',
                child: Image.file(
                  _capturedImage!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _capturedAt != null
                          ? 'Captured ${DateFormat('hh:mm a').format(_capturedAt!)}'
                          : 'Captured',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'View',
                  visualDensity: VisualDensity.compact,
                  onPressed: _openImageViewer,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPillButton(
                        icon: Icons.refresh_rounded,
                        label: 'Retake',
                        onPressed: canCapture ? _captureImage : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPillButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Remove',
                        isDestructive: true,
                        onPressed: enabled
                            ? () => setState(() {
                                _capturedImage = null;
                                _capturedAt = null;
                              })
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer() {
    if (_capturedImage == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Visit Photo', style: TextStyle(fontSize: 16)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Hero(
                tag: 'visit-photo',
                child: Image.file(_capturedImage!),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isDestructive = false,
  }) {
    final fg = isDestructive ? Colors.white : Colors.blue[700];
    return Material(
      color: isDestructive
          ? Colors.red.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastCounterSwitch({required bool enabled}) {
    final active = _isLastCounter;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active ? Colors.orange[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? Colors.orange[300]! : Colors.grey[200]!,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () => setState(() => _isLastCounter = !_isLastCounter)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: active ? Colors.orange[600] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: active
                        ? null
                        : Border.all(color: Colors.grey[200]!),
                  ),
                  child: Icon(
                    active ? Icons.flag_rounded : Icons.storefront_outlined,
                    size: 22,
                    color: active ? Colors.white : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Counter',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.orange[900] : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active
                            ? 'This is the final visit of the day'
                            : 'Turn on if this is your final visit today',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: active,
                  onChanged: enabled
                      ? (value) => setState(() => _isLastCounter = value)
                      : null,
                  activeTrackColor: Colors.orange[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.grey[700],
    ),
  );

  Widget _buildCustomerSearchField({
    required TextEditingController controller,
    required List<MessageElement> allCustomers,
    required bool enabled,
    required bool isLoading,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: (value) {
        if (_showSuccess) {
          setState(() => _showSuccess = false);
        }
        _filterCustomers(value, allCustomers);
      },
      onTap: () {
        if (allCustomers.isNotEmpty) {
          setState(() {
            _filteredCustomers = allCustomers;
            _showCustomerDropdown = true;
          });
        }
      },
      decoration: InputDecoration(
        hintText: 'Search or type customer name',
        prefixIcon: Icon(
          Icons.person_search,
          color: enabled ? Colors.grey[400] : Colors.grey[300],
        ),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: enabled
                    ? () {
                        controller.clear();
                        setState(() {
                          _selectedCustomer = null;
                          _filteredCustomers = [];
                          _showCustomerDropdown = false;
                        });
                      }
                    : null,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[50],
      ),
      style: TextStyle(
        fontSize: 16,
        color: enabled ? Colors.black : Colors.grey[400],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: (_) {
        if (_showSuccess) {
          setState(() => _showSuccess = false);
        }
      },
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: enabled ? Colors.grey[400] : Colors.grey[300])
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[50],
      ),
      style: TextStyle(
        fontSize: 16,
        color: enabled ? Colors.black : Colors.grey[400],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  static const double radius = 12;
  static const double strokeWidth = 1.5;
  static const double dashLength = 6;
  static const double gapLength = 4;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
