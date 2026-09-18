import 'package:flutter/material.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Mi coche',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
