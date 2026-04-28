import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart'; // This connects your main file to your dashboard

void main() {
  runApp(const DoctorDashboard());
}

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthCare Administration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DashboardScreen(), 
    );
  }
}