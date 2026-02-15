import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class UsersScreen extends StatefulWidget {
  final AuthService authService;

  const UsersScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  Widget build(BuildContext context) {
    final users = widget.authService.storage.users.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: users.isEmpty
          ? const Center(child: Text('No users found'))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final email = users[index].key;
                final user = users[index].value;
                final isLocked = widget.authService.isAccountLocked(email);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: user.role == 'manager'
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                          child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                        ),
                        if (isLocked)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Text(user.name),
                        if (user.isArchived) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Archived',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        if (isLocked)
                          const Text(
                            'Account Locked',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(
                            user.role,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              user.role == 'manager' ? Colors.blue.shade100 : Colors.green.shade100,
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleUserAction(value, email, user),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'reset_password',
                              child: ListTile(
                                leading: Icon(Icons.password),
                                title: Text('Reset Password'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (isLocked)
                              const PopupMenuItem(
                                value: 'unlock',
                                child: ListTile(
                                  leading: Icon(Icons.lock_open, color: Colors.green),
                                  title: Text('Unlock Account'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit User'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (!user.isArchived)
                              const PopupMenuItem(
                                value: 'archive',
                                child: ListTile(
                                  leading: Icon(Icons.archive, color: Colors.orange),
                                  title: Text('Archive User'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              )
                            else
                              const PopupMenuItem(
                                value: 'unarchive',
                                child: ListTile(
                                  leading: Icon(Icons.unarchive, color: Colors.blue),
                                  title: Text('Unarchive User'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: isLocked,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleUserAction(String action, String email, User user) {
    switch (action) {
      case 'reset_password':
        _resetPassword(email, user);
        break;
      case 'unlock':
        _unlockAccount(email);
        break;
      case 'edit':
        _editUser(email, user);
        break;
      case 'archive':
        _archiveUser(email, user);
        break;
      case 'unarchive':
        _unarchiveUser(email, user);
        break;
    }
  }

  void _resetPassword(String email, User user) {
    final newPasswordController = TextEditingController(text: 'temp1234');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset password for ${user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Default: temp1234',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPassword = newPasswordController.text.trim();
              if (newPassword.isEmpty) return;

              setState(() {
                widget.authService.storage.users[email] = user.copyWith(
                  password: newPassword,
                );
                // Also unlock the account when resetting password
                widget.authService.resetFailedAttempts(email);
              });
              widget.authService.storage.saveData();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset for ${user.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _unlockAccount(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Account'),
        content: const Text('This will reset failed login attempts and unlock the account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.authService.resetFailedAttempts(email);
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account unlocked'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _editUser(String email, User user) {
    final nameController = TextEditingController(text: user.name);
    String role = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              Text('Email: $email', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'technician', child: Text('Technician')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                onChanged: (v) => setDialogState(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;

                setState(() {
                  widget.authService.storage.users[email] = user.copyWith(
                    name: nameController.text,
                    role: role,
                  );
                });
                widget.authService.storage.saveData();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _archiveUser(String email, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive User'),
        content: Text('Archive ${user.name}? They will no longer be able to log in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              setState(() {
                widget.authService.storage.users[email] = user.copyWith(isArchived: true);
              });
              widget.authService.storage.saveData();
              Navigator.pop(context);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _unarchiveUser(String email, User user) {
    setState(() {
      widget.authService.storage.users[email] = user.copyWith(isArchived: false);
    });
    widget.authService.storage.saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} has been unarchived'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _createUser() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'temp1234');
    String role = 'technician';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    helperText: 'Default: temp1234',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'technician', child: Text('Technician')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim().toLowerCase();
                final name = nameController.text.trim();
                final password = passwordController.text.trim();

                if (email.isEmpty || name.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (!email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (widget.authService.storage.users.containsKey(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email already exists'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() {
                  widget.authService.storage.users[email] = User(
                    email: email,
                    name: name,
                    role: role,
                    password: password,
                  );
                });
                widget.authService.storage.saveData();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User $name created'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
