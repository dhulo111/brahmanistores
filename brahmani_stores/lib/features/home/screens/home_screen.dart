import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('બ્રહ્માણી પ્રોવિઝન સ્ટોર્સ'), // Brahmani Provision Stores
      ),
      body: const Center(
        child: Text('અહીં પ્રોડક્ટ્સ બતાવવામાં આવશે.'), // Products will be shown here
      ),
    );
  }
}
