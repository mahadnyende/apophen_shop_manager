import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/data/models/purchases/supplier_model.dart';
import 'package:apophen_shop_manager/services/supplier_service.dart';
import 'package:intl/intl.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  final SupplierService _supplierService = SupplierService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _supplierService.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _nameController.clear();
    _contactPersonController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  void _addSupplier() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier Name is required!')),
      );
      return;
    }

    try {
      final supplier = Supplier(
        name: _nameController.text,
        contactPerson: _contactPersonController.text.isNotEmpty ? _contactPersonController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
      );
      await _supplierService.addSupplier(supplier);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add supplier: ${e.toString()}')),
      );
    }
  }

  void _updateSupplier(Supplier supplier) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier Name is required for update!')),
      );
      return;
    }

    try {
      final updatedSupplier = Supplier(
        id: supplier.id, // Keep the existing ID
        name: _nameController.text,
        contactPerson: _contactPersonController.text.isNotEmpty ? _contactPersonController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        createdAt: supplier.createdAt, // Preserve original creation date
        lastModified: DateTime.now(), // Update last modified date
      );
      await _supplierService.updateSupplier(updatedSupplier);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update supplier: ${e.toString()}')),
      );
    }
  }

  void _showSupplierDialog(BuildContext context, {Supplier? supplier}) {
    _clearControllers(); // Clear controllers before showing dialog
    if (supplier != null) {
      // Populate if editing an existing supplier
      _nameController.text = supplier.name;
      _contactPersonController.text = supplier.contactPerson ?? '';
      _emailController.text = supplier.email ?? '';
      _phoneController.text = supplier.phone ?? '';
      _addressController.text = supplier.address ?? '';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(supplier == null ? 'Add New Supplier' : 'Edit Supplier: ${supplier.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Supplier Name*'),
                ),
                TextField(
                  controller: _contactPersonController,
                  decoration: const InputDecoration(labelText: 'Contact Person'),
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
                if (supplier == null) {
                  _addSupplier();
                } else {
                  _updateSupplier(supplier);
                }
                Navigator.of(context).pop();
              },
              child: Text(supplier == null ? 'Add Supplier' : 'Save Changes'),
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
        title: const Text('Supplier Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add New Supplier',
            onPressed: () => _showSupplierDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)], // Light blue/cyan gradient
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
                      backgroundColor: Colors.lightBlue.withOpacity(0.1),
                      child: const Icon(Icons.business, color: Colors.lightBlue),
                    ),
                    title: Text(
                      supplier.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty)
                          Text('Contact: ${supplier.contactPerson}'),
                        if (supplier.email != null && supplier.email!.isNotEmpty)
                          Text('Email: ${supplier.email}'),
                        if (supplier.phone != null && supplier.phone!.isNotEmpty)
                          Text('Phone: ${supplier.phone}'),
                        if (supplier.address != null && supplier.address!.isNotEmpty)
                          Text('Address: ${supplier.address}'),
                        Text('Added: ${DateFormat('MMM d,yyyy').format(supplier.createdAt.toLocal())}'),
                        Text('Last Update: ${DateFormat('MMM d,yyyy').format(supplier.lastModified.toLocal())}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showSupplierDialog(context, supplier: supplier);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _supplierService.deleteSupplier(supplier.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${supplier.name} deleted!')),
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
