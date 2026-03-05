import 'package:flutter/material.dart';
import 'package:pos_inventory/features/user/auth_controller.dart';
import 'package:pos_inventory/models/user_model.dart';
import 'package:provider/provider.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});
  static const Color _primaryBlue = Color(0xFF1D61E7);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Anda belum login')));
    }
    if (!auth.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Anda tidak memiliki akses')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showUserDialog(context);
        },
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: auth.user.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final user = auth.user[index];
            final roleLabel = user.role.name.toUpperCase();
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF1FF), Color(0xFFDDE9FF)],
                ),
                border: Border.all(color: const Color(0xFFBBD0FF)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_outline, color: _primaryBlue),
                ),
                title: Text(
                  user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Color(0xFF174FBF),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showUserDialog(context, user: user),
                      icon: const Icon(Icons.edit_outlined, color: _primaryBlue),
                    ),
                    IconButton(
                      onPressed: () => auth.deleteUser(user.id),
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(user == null ? 'Add User' : 'Edit User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameC,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordC,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: role,
                    items: UserRole.values.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r.name));
                    }).toList(),
                    onChanged: (v) => setLocal(() => role = v!),
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Color(0xFF334155)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    String? error;
                    if (user == null) {
                      error = await auth.addUser(
                        username: usernameC.text.trim(),
                        password: passwordC.text,
                        role: role,
                      );
                    } else {
                      error = await auth.editUser(
                        id: user.id,
                        username: usernameC.text.trim(),
                        password: passwordC.text,
                        role: role,
                      );
                    }

                    if (error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
