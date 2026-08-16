import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('બ્રહ્માણી પ્રોવિઝન સ્ટોર્સ'), // Brahmani Provision Stores
      ),
      body: const Center(
        child: Text('અહીં ડેશબોર્ડ બતાવવામાં આવશે.'), // Dashboard will be shown here
      ),
    );
  }
}
