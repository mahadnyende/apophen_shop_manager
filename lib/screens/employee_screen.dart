import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/data/models/crm/employee_model.dart';
import 'package:apophen_shop_manager/services/employee_service.dart';
import 'package:intl/intl.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _hireDateController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hireDateController.dispose();
    _employeeService.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _nameController.clear();
    _roleController.clear();
    _emailController.clear();
    _phoneController.clear();
    _hireDateController.clear();
  }

  Future<void> _selectHireDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _hireDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addEmployee() async {
    if (_nameController.text.isEmpty || _roleController.text.isEmpty || _hireDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, Role, and Hire Date are required!')),
      );
      return;
    }

    try {
      final employee = Employee(
        name: _nameController.text,
        role: _roleController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        hireDate: DateTime.parse(_hireDateController.text),
      );
      await _employeeService.addEmployee(employee);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add employee: ${e.toString()}')),
      );
    }
  }

  void _updateEmployee(Employee employee) async {
    if (_nameController.text.isEmpty || _roleController.text.isEmpty || _hireDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, Role, and Hire Date are required for update!')),
      );
      return;
    }

    try {
      final updatedEmployee = Employee(
        id: employee.id, // Keep the existing ID
        name: _nameController.text,
        role: _roleController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        hireDate: DateTime.parse(_hireDateController.text),
        lastModified: DateTime.now(), // Update last modified date
      );
      await _employeeService.updateEmployee(updatedEmployee);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update employee: ${e.toString()}')),
      );
    }
  }

  void _showEmployeeDialog(BuildContext context, {Employee? employee}) {
    _clearControllers(); // Clear controllers before showing dialog
    if (employee != null) {
      // Populate if editing an existing employee
      _nameController.text = employee.name;
      _roleController.text = employee.role;
      _emailController.text = employee.email ?? '';
      _phoneController.text = employee.phone ?? '';
      _hireDateController.text = DateFormat('yyyy-MM-dd').format(employee.hireDate);
    } else {
      _hireDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Default to today for new employee
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(employee == null ? 'Add New Employee' : 'Edit Employee: ${employee.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Employee Name*'),
                ),
                TextField(
                  controller: _roleController,
                  decoration: const InputDecoration(labelText: 'Role* (e.g., Manager, Sales Associate)'),
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
                GestureDetector(
                  onTap: () => _selectHireDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _hireDateController,
                      decoration: const InputDecoration(
                        labelText: 'Hire Date*',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
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
                if (employee == null) {
                  _addEmployee();
                } else {
                  _updateEmployee(employee);
                }
                Navigator.of(context).pop();
              },
              child: Text(employee == null ? 'Add Employee' : 'Save Changes'),
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
        title: const Text('Employee Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            tooltip: 'Add New Employee',
            onPressed: () => _showEmployeeDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F7), Color(0xFFB2EBF2)], // Light teal gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<Employee>>(
          stream: _employeeService.getEmployees(),
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
                    Icon(Icons.people, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No employees found. Add your first employee!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final employees = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                      child: const Icon(Icons.person_outline, color: Colors.teal),
                    ),
                    title: Text(
                      employee.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Role: ${employee.role}'),
                        if (employee.email != null && employee.email!.isNotEmpty)
                          Text('Email: ${employee.email}'),
                        if (employee.phone != null && employee.phone!.isNotEmpty)
                          Text('Phone: ${employee.phone}'),
                        Text('Hire Date: ${DateFormat('MMM d,yyyy').format(employee.hireDate.toLocal())}'),
                        Text('Last Update: ${DateFormat('MMM d,yyyy').format(employee.lastModified.toLocal())}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showEmployeeDialog(context, employee: employee);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _employeeService.deleteEmployee(employee.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${employee.name} deleted!')),
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
