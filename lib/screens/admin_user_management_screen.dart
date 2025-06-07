// lib/screens/admin_user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/models/user_model.dart';
import 'package:apophen_shop_manager/services/user_service.dart';
import 'package:intl/intl.dart'; // For date formatting

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final UserService _userService = UserService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.employee; // Default role for new users

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _userService.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _usernameController.clear();
    _passwordController.clear();
    _selectedRole = UserRole.employee; // Reset to default
  }

  void _addUser() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and Password are required!')),
      );
      return;
    }

    try {
      final user = User(
        username: _usernameController.text,
        password: _passwordController.text, // In a real app, hash this!
        role: _selectedRole,
      );
      await _userService.addUser(user);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add user: ${e.toString()}')),
      );
    }
  }

  void _updateUser(User user) async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Username and Password are required for update!')),
      );
      return;
    }

    try {
      final updatedUser = User(
        id: user.id, // Keep existing ID
        username: _usernameController.text,
        password: _passwordController.text, // In a real app, hash this!
        role: _selectedRole,
        createdAt: user.createdAt,
        lastModified: DateTime.now(), // Update last modified
      );
      await _userService.updateUser(updatedUser);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user: ${e.toString()}')),
      );
    }
  }

  void _showUserDialog(BuildContext context, {User? user}) {
    _clearControllers(); // Clear controllers before showing dialog
    if (user != null) {
      // Populate if editing an existing user
      _usernameController.text = user.username;
      _passwordController.text = user
          .password; // For editing, show current password (not ideal for production)
      _selectedRole = user.role;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              user == null ? 'Add New User' : 'Edit User: ${user.username}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username*'),
                  readOnly: user !=
                      null, // Username cannot be changed if editing existing user
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password*'),
                  obscureText: true, // Hide password input
                ),
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: UserRole.values
                      .where((role) => role != UserRole.unknown)
                      .map((role) {
                    return DropdownMenuItem<UserRole>(
                      value: role,
                      child:
                          Text(role.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (UserRole? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRole = newValue;
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
                _clearControllers();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (user == null) {
                  _addUser();
                } else {
                  _updateUser(user);
                }
                Navigator.of(context).pop();
              },
              child: Text(user == null ? 'Add User' : 'Save Changes'),
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
        title: const Text('User Management',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add New User',
            onPressed: () => _showUserDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB)
            ], // Light blue gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<User>>(
          stream: _userService.getUsers(),
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
                    Icon(Icons.person_off, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No users found. Add your first user!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final users = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
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
                          const Icon(Icons.person_outline, color: Colors.blue),
                    ),
                    title: Text(
                      user.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Role: ${user.role.toString().split('.').last.toUpperCase()}'),
                        Text(
                            'Created: ${DateFormat('MMM d,yyyy').format(user.createdAt.toLocal())}'),
                        Text(
                            'Last Modified: ${DateFormat('MMM d,yyyy').format(user.lastModified.toLocal())}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showUserDialog(context, user: user);
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            // Prevent deleting the only admin or the current user if needed
                            await _userService.deleteUser(user.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('${user.username} deleted!')),
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
