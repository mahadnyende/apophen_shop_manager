// lib/screens/supplier_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/supplier_service.dart';
import 'package:apophen_shop_manager/data/models/purchases/supplier_model.dart';
import 'package:intl/intl.dart'; // Required for date formatting

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final SupplierService _supplierService = SupplierService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _supplierService.dispose(); // Dispose the stream controller
    super.dispose();
  }

  void _clearControllers() {
    _nameController.clear();
    _contactPersonController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
  }

  void _addSupplier() async {
    if (_nameController.text.isEmpty || _contactPersonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Supplier Name and Contact Person are required!')),
      );
      return;
    }

    try {
      final supplier = Supplier(
        name: _nameController.text,
        contactPerson: _contactPersonController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
      );
      await _supplierService.addSupplier(supplier);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${supplier.name} added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add supplier: ${e.toString()}')),
      );
    }
  }

  void _updateSupplier(Supplier supplier) async {
    if (_nameController.text.isEmpty || _contactPersonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Supplier Name and Contact Person are required for update!')),
      );
      return;
    }

    try {
      final updatedSupplier = Supplier(
        id: supplier.id, // Keep the existing ID
        name: _nameController.text,
        contactPerson: _contactPersonController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        createdAt: supplier.createdAt, // Preserve original creation date
        lastModified: DateTime.now(), // Update last modified date
      );
      await _supplierService.updateSupplier(updatedSupplier);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${updatedSupplier.name} updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update supplier: ${e.toString()}')),
      );
    }
  }

  void _showAddSupplierDialog(BuildContext context) {
    _clearControllers(); // Clear controllers before showing add dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Supplier'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Supplier Name *'),
                ),
                TextField(
                  controller: _contactPersonController,
                  decoration:
                      const InputDecoration(labelText: 'Contact Person *'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
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
                _addSupplier();
                Navigator.of(context).pop(); // Close dialog after adding
              },
              child: const Text('Add Supplier'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSupplierDialog(BuildContext context, Supplier supplier) {
    // Populate controllers with existing supplier data
    _nameController.text = supplier.name;
    _contactPersonController.text = supplier.contactPerson;
    _phoneController.text = supplier.phoneNumber;
    _emailController.text = supplier.email;
    _addressController.text = supplier.address ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Supplier: ${supplier.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Supplier Name *'),
                ),
                TextField(
                  controller: _contactPersonController,
                  decoration:
                      const InputDecoration(labelText: 'Contact Person *'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
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
                _updateSupplier(supplier); // Pass the original supplier for ID
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
        title: const Text('Supplier Management',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add New Supplier',
            onPressed: () => _showAddSupplierDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0F2F7),
              Color(0xFFB3EBF5)
            ], // Light blue-green gradient for suppliers
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<Supplier>>(
          stream: _supplierService.getSuppliers(),
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
                    Icon(Icons.local_shipping, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No suppliers found. Add your first supplier!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final suppliers = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
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
                      child:
                          const Icon(Icons.business, color: Colors.lightBlue),
                    ),
                    title: Text(
                      supplier.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact: ${supplier.contactPerson}'),
                        if (supplier.email.isNotEmpty)
                          Text('Email: ${supplier.email}'),
                        if (supplier.phoneNumber.isNotEmpty)
                          Text('Phone: ${supplier.phoneNumber}'),
                        if (supplier.address != null &&
                            supplier.address!.isNotEmpty)
                          Text('Address: ${supplier.address}'),
                        Text(
                            'Added: ${DateFormat('yyyy-MM-dd').format(supplier.createdAt)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showEditSupplierDialog(context, supplier);
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _supplierService.deleteSupplier(supplier.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('${supplier.name} deleted!')),
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
