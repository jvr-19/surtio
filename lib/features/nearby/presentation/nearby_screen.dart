import 'package:flutter/material.dart';

class NearbyScreen extends StatelessWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Cerca',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
