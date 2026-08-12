import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../core/theme.dart';
import '../providers/verification_provider.dart';
import '../models/pending_user.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('બ્રહ્માણી પ્રોવિઝન સ્ટોર્સ'), // Brahmani Provision Stores
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: state.isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : state.pendingUsers.isEmpty
                  ? Center(
                      child: Text(
                        'કોઈ નવી રિક્વેસ્ટ નથી (No pending requests)',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.surfaceDark,
                      onRefresh: () => ref.read(verificationProvider.notifier).fetchPendingUsers(),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100), // Added bottom padding to clear the nav bar
                        itemCount: state.pendingUsers.length,
                        itemBuilder: (context, index) {
                          final user = state.pendingUsers[index];
                          return PendingUserCard(user: user);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PendingUserCard extends ConsumerStatefulWidget {
  final PendingUser user;
  
  const PendingUserCard({super.key, required this.user});

  @override
  ConsumerState<PendingUserCard> createState() => _PendingUserCardState();
}

class _PendingUserCardState extends ConsumerState<PendingUserCard> {
  bool _isLoading = false;

  void _processAction(String action) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    bool success = await ref.read(verificationProvider.notifier).processUser(widget.user.id, action);
    
    if (mounted) {
      if (!success) {
        // If it failed, stop loading so they can try again
        setState(() {
          _isLoading = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? (action == 'APPROVE' ? 'સફળતાપૂર્વક મંજૂર કરવામાં આવ્યું (Approved)' : 'રિક્વેસ્ટ રદ કરવામાં આવી (Rejected)')
                : 'ભૂલ આવી (Error processing request)'
          ),
          backgroundColor: success 
              ? (action == 'APPROVE' ? AppTheme.primaryGreen : Colors.orange) 
              : Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(widget.user.avatarUrl),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.user.firstName} ${widget.user.lastName}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.phone,
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                          Text(
                            widget.user.email,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => _processAction('REJECT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent)
                            )
                          : const Text('રદ કરો (Reject)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _processAction('APPROVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark)
                            )
                          : const Text('મંજૂર કરો (Approve)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

