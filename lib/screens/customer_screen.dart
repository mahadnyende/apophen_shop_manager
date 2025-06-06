// lib/screens/customer_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/customer_service.dart';
import 'package:apophen_shop_manager/data/models/crm/customer_model.dart';
import 'package:intl/intl.dart'; // Required for date formatting, add to pubspec.yaml if not already there

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _customerService.dispose(); // Dispose the stream controller
    super.dispose();
  }

  void _clearControllers() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  void _addCustomer() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First Name and Last Name are required!')),
      );
      return;
    }

    try {
      final customer = Customer(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
      );
      await _customerService.addCustomer(customer);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${customer.fullName} added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add customer: ${e.toString()}')),
      );
    }
  }

  void _updateCustomer(Customer customer) async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('First Name and Last Name are required for update!')),
      );
      return;
    }

    try {
      final updatedCustomer = Customer(
        id: customer.id, // Keep the existing ID
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        createdAt: customer.createdAt, // Preserve original creation date
        lastModified: DateTime.now(), // Update last modified date
      );
      await _customerService.updateCustomer(updatedCustomer);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${updatedCustomer.fullName} updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update customer: ${e.toString()}')),
      );
    }
  }

  void _showAddCustomerDialog(BuildContext context) {
    _clearControllers(); // Clear controllers before showing add dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name *'),
                ),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name *'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addCustomer();
                Navigator.of(context).pop(); // Close dialog after adding
              },
              child: const Text('Add Customer'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    // Populate controllers with existing customer data
    _firstNameController.text = customer.firstName;
    _lastNameController.text = customer.lastName;
    _emailController.text = customer.email;
    _phoneController.text = customer.phoneNumber;
    _addressController.text = customer.address ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Customer: ${customer.fullName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name *'),
                ),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name *'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearControllers(); // Clear controllers on cancel
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateCustomer(customer); // Pass the original customer for ID
                Navigator.of(context).pop(); // Close dialog after updating
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add New Customer',
            onPressed: () => _showAddCustomerDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF3E0),
              Color(0xFFFFECB3)
            ], // Light orange gradient for customers
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<Customer>>(
          stream: _customerService.getCustomers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No customers found. Add your first customer!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final customers = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.person, color: Colors.orange),
                    ),
                    title: Text(
                      customer.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customer.email.isNotEmpty)
                          Text('Email: ${customer.email}'),
                        if (customer.phoneNumber.isNotEmpty)
                          Text('Phone: ${customer.phoneNumber}'),
                        if (customer.address != null &&
                            customer.address!.isNotEmpty)
                          Text('Address: ${customer.address}'),
                        Text(
                            'Joined: ${DateFormat('yyyy-MM-dd').format(customer.createdAt)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showEditCustomerDialog(context, customer);
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _customerService.deleteCustomer(customer.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('${customer.fullName} deleted!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
