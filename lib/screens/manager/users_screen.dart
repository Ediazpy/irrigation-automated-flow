import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user.dart';

class UsersScreen extends StatefulWidget {
  final AuthService authService;

  const UsersScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _busy = false;

  Future<void> _refreshUsers() async {
    try {
      final users = await FirestoreService().getAllUsers();
      widget.authService.storage.users
        ..clear()
        ..addAll(users);
      await widget.authService.storage.saveData();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _showError(Object e) {
    if (!mounted) return;
    String message;
    if (e is FirebaseFunctionsException) {
      // Server-side validation errors carry a human-readable message;
      // infrastructure errors don't, so translate the common codes.
      message = e.message != null && e.message!.isNotEmpty && e.message != 'null'
          ? e.message!
          : switch (e.code) {
              'unauthenticated' => 'Your session expired. Sign out and back in.',
              'permission-denied' => 'Only managers can do this.',
              'not-found' || 'unavailable' || 'internal' =>
                'The server is unavailable right now. Try again in a moment.',
              _ => 'Something went wrong (${e.code}). Try again.',
            };
    } else {
      message = 'Something went wrong. Check your connection and try again.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.authService.storage.users.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Stack(
        children: [
          users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].value;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.role == 'manager'
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                          child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                        ),
                        title: Row(
                          children: [
                            Text(user.name),
                            if (user.isArchived) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
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
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                user.role,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: user.role == 'manager'
                                  ? Colors.blue.shade100
                                  : Colors.green.shade100,
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) => _handleUserAction(value, user),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'reset_password',
                                  child: ListTile(
                                    leading: Icon(Icons.password),
                                    title: Text('Send Password Reset'),
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
                                      leading:
                                          Icon(Icons.archive, color: Colors.orange),
                                      title: Text('Archive User'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  )
                                else
                                  const PopupMenuItem(
                                    value: 'unarchive',
                                    child: ListTile(
                                      leading:
                                          Icon(Icons.unarchive, color: Colors.blue),
                                      title: Text('Unarchive User'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          if (_busy)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _createUser,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleUserAction(String action, User user) {
    switch (action) {
      case 'reset_password':
        _resetPassword(user);
        break;
      case 'edit':
        _editUser(user);
        break;
      case 'archive':
        _archiveUser(user);
        break;
      case 'unarchive':
        _unarchiveUser(user);
        break;
    }
  }

  void _resetPassword(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Password Reset'),
        content: Text(
          'Send a password reset email to ${user.email}? '
          'They\'ll get a link to choose a new password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.authService.sendPasswordReset(user.email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset email sent to ${user.email}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showError(e);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _editUser(User user) {
    final nameController = TextEditingController(text: user.name);
    String role = user.role;
    final isSelf = user.uid == widget.authService.currentUser?.uid;

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
              Text('Email: ${user.email}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'technician', child: Text('Technician')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                // Changing your own role could lock the company out of
                // admin access — the server refuses it, so don't offer it.
                onChanged: isSelf ? null : (v) => setDialogState(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                Navigator.pop(context);
                setState(() => _busy = true);
                try {
                  if (nameController.text != user.name) {
                    await FirestoreService()
                        .saveUser(user.copyWith(name: nameController.text));
                  }
                  if (role != user.role) {
                    await widget.authService.setUserRole(user.uid, role);
                  }
                  await _refreshUsers();
                } catch (e) {
                  _showError(e);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _archiveUser(User user) {
    if (user.uid == widget.authService.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot archive your own account'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive User'),
        content: Text(
            'Archive ${user.name}? Their sign-in will be disabled and they will no longer be able to log in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _busy = true);
              try {
                await widget.authService.setUserArchived(user.uid, true);
                await _refreshUsers();
              } catch (e) {
                _showError(e);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _unarchiveUser(User user) async {
    setState(() => _busy = true);
    try {
      await widget.authService.setUserArchived(user.uid, false);
      await _refreshUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} has been unarchived'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _createUser() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
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
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Password',
                    border: OutlineInputBorder(),
                    helperText: 'At least 6 characters — they can change it later',
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
              onPressed: () async {
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

                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _busy = true);
                try {
                  await widget.authService.createUser(
                    email: email,
                    password: password,
                    name: name,
                    role: role,
                  );
                  await _refreshUsers();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User $name created'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  _showError(e);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
