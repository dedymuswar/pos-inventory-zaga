import 'package:flutter/material.dart';
import 'package:pos_inventory/features/user/auth_controller.dart';
import 'package:pos_inventory/models/user_model.dart';
import 'package:provider/provider.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: Text('Anda belum login'),
        ),
      );
    }
    if (!auth.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Anda tidak memiliki akses'),
        ),
      );
    }

    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      actions: [
        IconButton(onPressed: () => auth.logout(),
        icon: const Icon(Icons.logout),
        )
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        _showUserDialog(context);
      },
      child: const Icon(Icons.add),
    ),
    body: ListView.builder(
      itemCount: auth.user.length,
      itemBuilder: (context, index){
      final user = auth.user[index];
      return ListTile(
        title: Text(user.username),
        subtitle: Text(user.role.toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showUserDialog(context, user: user),
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () => auth.deleteUser(user.id),
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      );    
    },
    
    ),
    );
  }

  void _showUserDialog(BuildContext context, {AppUser? user}) {
    final auth = context.read<AuthController>();
    final usernameC = TextEditingController(text: user?.username ?? '');
    final passwordC = TextEditingController(text: user?.password ?? '');
    UserRole role = user?.role ?? UserRole.kasir;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setLocal){
          return AlertDialog(
            title: Text(user == null ? 'Add User' : 'Edit User'),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameC,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    controller: passwordC,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    items: UserRole.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r.name),
                      );
                    }).toList(),
                    onChanged: (v) => setLocal(() => role = v!),
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String? error;
                    if (user == null) {
                      error = auth.addUser(
                        username: usernameC.text.trim(),
                        password: passwordC.text,
                        role: role,
                      );
                    } else {
                      error = auth.editUser(
                        id: user.id,
                        username: usernameC.text.trim(),
                        password: passwordC.text,
                        role: role,
                      );
                    }

                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                      return;
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
          );
        });
      },
    );
  }
}