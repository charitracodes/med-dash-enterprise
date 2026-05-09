import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
// Ensure these files exist in your lib/screens/ folder
import 'patients_screen.dart'; 
import 'schedule_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';

class ClinicManagement extends StatelessWidget {
  final VoidCallback onThemeToggle;
  const ClinicManagement({super.key, required this.onThemeToggle});

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clinic Management"),
        actions: [
          IconButton(onPressed: onThemeToggle, icon: const Icon(Icons.brightness_6)),
          IconButton(onPressed: () => _handleLogout(context), icon: const Icon(Icons.logout)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                // FIXED: Passing the specific screen to the builder
                _buildCard(context, "Patients", Icons.people, const Color.fromARGB(255, 243, 117, 33), const PatientsScreen()),
                const SizedBox(width: 20),
                _buildCard(context, "Schedule", Icons.event, const Color.fromARGB(255, 115, 255, 0), const ScheduleScreen()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildCard(context, "Inventory", Icons.inventory_2, Colors.teal, const InventoryScreen()),
                const SizedBox(width: 20),
                _buildCard(context, "Reports", Icons.assessment, Colors.purple, const ReportsScreen()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, Widget targetScreen) {
    return Expanded(
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell( // Using InkWell for the ripple effect and tap
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // FIXED: This is what "accesses" the inside of the card
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => targetScreen)
            );
          },
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).cardColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Added Hero tag for the logo/icon transition
                Hero(
                  tag: title, 
                  child: Icon(icon, size: 50, color: color),
                ),
                const SizedBox(height: 15),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}