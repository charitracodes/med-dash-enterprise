import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  static final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clinic Analytics")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statItem("Total Patients Registered", _db.getPatients()),
          _statItem("Total Appointments Scheduled", _db.getAppointments()),
        ],
      ),
    );
  }

  Widget _statItem(String label, Stream stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        int count = snapshot.hasData ? (snapshot.data as List).length : 0;
        return Card(
          child: ListTile(title: Text(label), trailing: Text("$count", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        );
      },
    );
  }
}