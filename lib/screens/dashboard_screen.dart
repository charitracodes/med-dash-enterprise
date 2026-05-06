import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'patients_screen.dart';
import 'schedule_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function onThemeToggle;
  const DashboardScreen({super.key, required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clinic Management"),
        actions: [
          IconButton(icon: const Icon(Icons.brightness_6), onPressed: () => onThemeToggle()),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _menuCard(context, "Patients", Icons.person_search, Colors.blue, const PatientsScreen()),
          _menuCard(context, "Schedule", Icons.calendar_today, Colors.orange, const ScheduleScreen()),
          _menuCard(context, "Inventory", Icons.medical_services, Colors.teal, const InventoryScreen()),
          _menuCard(context, "Reports", Icons.bar_chart, Colors.purple, const ReportsScreen()),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, IconData icon, Color color, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 40, color: color), const SizedBox(height: 8), Text(title)],
        ),
      ),
    );
  }
}