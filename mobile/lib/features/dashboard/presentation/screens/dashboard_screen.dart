import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.receipt_long),
          label: const Text('View Expenses'),
          onPressed: () => context.push('/expenses'),
        ),
      ),
    );
  }
}
