import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/user_management_provider.dart';
import '../models/admin_user_model.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/nav_provider.dart';
import 'package:go_router/go_router.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    
    final filteredUsers = state.users.where((user) {
      final query = _searchQuery.toLowerCase();
      return user.firstName.toLowerCase().contains(query) ||
             user.lastName.toLowerCase().contains(query) ||
             user.email.toLowerCase().contains(query) ||
             user.phone.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('યુઝર મેનેજમેન્ટ'), // User Management
        centerTitle: true,
      ),
      body: state.isLoading && state.users.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: const TextStyle(color: AppTheme.errorColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(userManagementProvider.notifier).fetchUsers(),
                        child: const Text('ફરી પ્રયાસ કરો (Retry)'),
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'નામ, ઇમેઇલ અથવા નંબરથી શોધો...', // Search by name, email or number...
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(userManagementProvider.notifier).fetchUsers(),
                    child: filteredUsers.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text('કોઈ યુઝર મળ્યો નથી', style: TextStyle(color: AppTheme.textSecondary)),
                              )
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return _UserCard(user: user);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AdminUser user;
  const _UserCard({required this.user});

  void _showEditSheet(BuildContext context, WidgetRef ref) async {
    ref.read(navBarVisibilityProvider.notifier).state = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditUserSheet(user: user),
    );
    ref.read(navBarVisibilityProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showEditSheet(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 2),
                      image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                          : null,
                      color: AppTheme.primaryDark,
                    ),
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(user.phone.isEmpty ? '-' : user.phone, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.email_rounded, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(child: Text(user.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.role == 'ADMIN' 
                              ? Colors.purpleAccent.withOpacity(0.15) 
                              : Colors.blueAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: user.role == 'ADMIN' ? Colors.purpleAccent.withOpacity(0.3) : Colors.blueAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(user.role == 'ADMIN' ? Icons.admin_panel_settings : Icons.person, 
                                 size: 12, 
                                 color: user.role == 'ADMIN' ? Colors.purpleAccent : Colors.blueAccent),
                            const SizedBox(width: 4),
                            Text(
                              user.role,
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold,
                                color: user.role == 'ADMIN' ? Colors.purpleAccent : Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(user.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(user.status).withOpacity(0.3)),
                        ),
                        child: Text(
                          user.status,
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(user.status),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED': return AppTheme.primaryGreen;
      case 'PENDING': return Colors.orangeAccent;
      case 'REJECTED': return AppTheme.errorColor;
      default: return Colors.grey;
    }
  }
}

class _EditUserSheet extends ConsumerStatefulWidget {
  final AdminUser user;
  const _EditUserSheet({required this.user});

  @override
  ConsumerState<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends ConsumerState<_EditUserSheet> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late String _selectedRole;
  late String _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _selectedRole = widget.user.role;
    _selectedStatus = widget.user.status;
  }

  void _save() async {
    setState(() => _isSaving = true);
    final success = await ref.read(userManagementProvider.notifier).updateUser(
      widget.user.id,
      {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phone': _phoneController.text,
        'email': widget.user.email,
        'role': _selectedRole,
        'status': _selectedStatus,
      }
    );
    setState(() => _isSaving = false);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('યુઝર અપડેટ સફળ (Updated)')));
    }
  }

  void _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('ખાતરી કરો (Confirm)'),
        content: const Text('શું તમે ખરેખર આ યુઝરને ડિલીટ કરવા માંગો છો? (Are you sure?)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ના (No)', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('હા, ડિલીટ કરો (Yes)', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      final success = await ref.read(userManagementProvider.notifier).deleteUser(widget.user.id);
      setState(() => _isSaving = false);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('યુઝર ડિલીટ થઈ ગયો (Deleted)')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, 
        right: 24, 
        top: 24, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('યુઝર એડિટ કરો', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'પહેલું નામ (First Name)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'અટક (Last Name)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'મોબાઇલ (Mobile)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'રોલ (Role)'),
              dropdownColor: AppTheme.surfaceDark,
              items: const [
                DropdownMenuItem(value: 'USER', child: Text('USER')),
                DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'સ્ટેટસ (Status)'),
              dropdownColor: AppTheme.surfaceDark,
              items: const [
                DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
                DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close sheet
                            GoRouter.of(context).push('/users/ledger/${widget.user.id}', extra: {'userName': '${widget.user.firstName} ${widget.user.lastName}'});
                          },
                          icon: const Icon(Icons.menu_book),
                          label: const Text('ખાતું જુઓ (View Ledger)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _delete,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                                side: const BorderSide(color: AppTheme.errorColor),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('ડિલીટ કરો'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('સાચવો (Save)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
