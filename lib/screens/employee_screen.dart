// lib/screens/employee_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/employee_service.dart';
import 'package:apophen_shop_manager/data/models/employees/employee_model.dart';
import 'package:intl/intl.dart'; // Required for date formatting

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  DateTime? _selectedHireDate;

  @override
  void initState() {
    super.initState();
    _selectedHireDate = DateTime.now(); // Default to today's date
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    _employeeService.dispose(); // Dispose the stream controller
    super.dispose();
  }

  void _clearControllers() {
    _firstNameController.clear();
    _lastNameController.clear();
    _positionController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _salaryController.clear();
    setState(() {
      _selectedHireDate = DateTime.now();
    });
  }

  Future<void> _selectHireDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedHireDate ?? DateTime.now(),
      firstDate: DateTime(1900), // Far back enough for hire dates
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedHireDate) {
      setState(() {
        _selectedHireDate = picked;
      });
    }
  }

  void _addEmployee() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _positionController.text.isEmpty ||
        _selectedHireDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'First Name, Last Name, Position, and Hire Date are required!')),
      );
      return;
    }
    double? salary;
    if (_salaryController.text.isNotEmpty) {
      salary = double.tryParse(_salaryController.text);
      if (salary == null || salary < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a valid positive salary amount!')),
        );
        return;
      }
    }

    try {
      final employee = Employee(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        position: _positionController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        hireDate: _selectedHireDate!,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        salary: salary,
      );
      await _employeeService.addEmployee(employee);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${employee.fullName} added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add employee: ${e.toString()}')),
      );
    }
  }

  void _updateEmployee(Employee employee) async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _positionController.text.isEmpty ||
        _selectedHireDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'First Name, Last Name, Position, and Hire Date are required for update!')),
      );
      return;
    }
    double? salary;
    if (_salaryController.text.isNotEmpty) {
      salary = double.tryParse(_salaryController.text);
      if (salary == null || salary < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a valid positive salary amount!')),
        );
        return;
      }
    }

    try {
      final updatedEmployee = Employee(
        id: employee.id, // Keep the existing ID
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        position: _positionController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        hireDate: _selectedHireDate!,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        salary: salary,
        createdAt: employee.createdAt, // Preserve original creation date
        lastModified: DateTime.now(), // Update last modified date
      );
      await _employeeService.updateEmployee(updatedEmployee);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${updatedEmployee.fullName} updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update employee: ${e.toString()}')),
      );
    }
  }

  void _showAddEditEmployeeDialog({Employee? employee}) {
    _clearControllers(); // Clear for new, or will be populated below for edit
    bool isEditing = employee != null;

    if (isEditing) {
      _firstNameController.text = employee.firstName;
      _lastNameController.text = employee.lastName;
      _positionController.text = employee.position;
      _phoneController.text = employee.phoneNumber;
      _emailController.text = employee.email;
      _addressController.text = employee.address ?? '';
      _salaryController.text = employee.salary?.toString() ?? '';
      _selectedHireDate = employee.hireDate;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Employee' : 'Add New Employee'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name *'),
                    ),
                    TextField(
                      controller: _lastNameController,
                      decoration:
                          const InputDecoration(labelText: 'Last Name *'),
                    ),
                    TextField(
                      controller: _positionController,
                      decoration:
                          const InputDecoration(labelText: 'Position *'),
                    ),
                    TextField(
                      controller: _phoneController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
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
                    TextField(
                      controller: _salaryController,
                      decoration:
                          const InputDecoration(labelText: 'Salary (Optional)'),
                      keyboardType: TextInputType.number,
                    ),
                    ListTile(
                      title: Text(
                          'Hire Date: ${_selectedHireDate == null ? 'Select Date *' : DateFormat('yyyy-MM-dd').format(_selectedHireDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedHireDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null &&
                            pickedDate != _selectedHireDate) {
                          setStateInDialog(() {
                            // Update dialog's state
                            _selectedHireDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearControllers(); // Clear on cancel
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isEditing) {
                      _updateEmployee(employee!);
                    } else {
                      _addEmployee();
                    }
                    Navigator.of(context)
                        .pop(); // Close dialog after action attempt
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Employee'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add New Employee',
            onPressed: () => _showAddEditEmployeeDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEDE7F6),
              Color(0xFFD1C4E9)
            ], // Light purple gradient for employees
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
                    Icon(Icons.people_alt, size: 80, color: Colors.grey),
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
            // Sort by last name then first name
            employees.sort((a, b) {
              int lastNameComparison = a.lastName.compareTo(b.lastName);
              if (lastNameComparison != 0) {
                return lastNameComparison;
              }
              return a.firstName.compareTo(b.firstName);
            });

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
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.person_2, color: Colors.purple),
                    ),
                    title: Text(
                      employee.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Position: ${employee.position}'),
                        if (employee.email.isNotEmpty)
                          Text('Email: ${employee.email}'),
                        if (employee.phoneNumber.isNotEmpty)
                          Text('Phone: ${employee.phoneNumber}'),
                        Text(
                            'Hire Date: ${DateFormat('yyyy-MM-dd').format(employee.hireDate)}'),
                        if (employee.salary != null)
                          Text(
                              'Salary: \$${employee.salary!.toStringAsFixed(2)}'),
                        if (employee.address != null &&
                            employee.address!.isNotEmpty)
                          Text('Address: ${employee.address}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showAddEditEmployeeDialog(employee: employee);
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _employeeService.deleteEmployee(employee.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('${employee.fullName} deleted!')),
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
