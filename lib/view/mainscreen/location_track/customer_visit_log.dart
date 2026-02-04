import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
                      const SizedBox(height: 24),

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
