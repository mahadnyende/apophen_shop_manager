import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/data/models/crm/customer_model.dart';
import 'package:apophen_shop_manager/services/customer_service.dart';
import 'package:intl/intl.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _customerService.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  void _addCustomer() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer Name is required!')),
      );
      return;
    }

    try {
      final customer = Customer(
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
      );
      await _customerService.addCustomer(customer);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add customer: ${e.toString()}')),
      );
    }
  }

  void _updateCustomer(Customer customer) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer Name is required for update!')),
      );
      return;
    }

    try {
      final updatedCustomer = Customer(
        id: customer.id, // Keep the existing ID
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        createdAt: customer.createdAt, // Preserve original creation date
        lastModified: DateTime.now(), // Update last modified date
      );
      await _customerService.updateCustomer(updatedCustomer);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update customer: ${e.toString()}')),
      );
    }
  }

  void _showCustomerDialog(BuildContext context, {Customer? customer}) {
    _clearControllers(); // Clear controllers before showing dialog
    if (customer != null) {
      // Populate if editing an existing customer
      _nameController.text = customer.name;
      _emailController.text = customer.email ?? '';
      _phoneController.text = customer.phone ?? '';
      _addressController.text = customer.address ?? '';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(customer == null ? 'Add New Customer' : 'Edit Customer: ${customer.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Customer Name*'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearControllers();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (customer == null) {
                  _addCustomer();
                } else {
                  _updateCustomer(customer);
                }
                Navigator.of(context).pop();
              },
              child: Text(customer == null ? 'Add Customer' : 'Save Changes'),
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
        title: const Text('Customer Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add New Customer',
            onPressed: () => _showCustomerDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)], // Light pink gradient
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
                    Icon(Icons.people_alt, size: 80, color: Colors.grey),
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
                      backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      child: const Icon(Icons.person, color: Colors.pink),
                    ),
                    title: Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customer.email != null && customer.email!.isNotEmpty)
                          Text('Email: ${customer.email}'),
                        if (customer.phone != null && customer.phone!.isNotEmpty)
                          Text('Phone: ${customer.phone}'),
                        if (customer.address != null && customer.address!.isNotEmpty)
                          Text('Address: ${customer.address}'),
                        Text('Joined: ${DateFormat('MMM d, yyyy').format(customer.createdAt.toLocal())}'),
                        Text('Last Update: ${DateFormat('MMM d, yyyy').format(customer.lastModified.toLocal())}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showCustomerDialog(context, customer: customer);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _customerService.deleteCustomer(customer.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${customer.name} deleted!')),
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
