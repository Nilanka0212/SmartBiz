import 'package:flutter/material.dart';

class PreviousOrdersPage extends StatelessWidget {
  const PreviousOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.green),
          SizedBox(height: 16),
          Text('Previous Orders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Coming soon...', style: TextStyle(color: Colors.black45)),
        ],
      ),
    );
  }
}