import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../models/appointment_model.dart';
import '../models/patient_model.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  static final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Clinic Analytics"),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Operational Insights",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 1. DYNAMIC STAT CARDS (Based on your previous _statItem logic)
            StreamBuilder<List<Patient>>(
              stream: _db.getPatients(),
              builder: (context, snapshot) {
                int patientCount = snapshot.hasData ? snapshot.data!.length : 0;
                return _buildStatCard(
                  "Registered Patients",
                  patientCount.toString(),
                  Icons.person_add_alt_1,
                  Colors.blue.shade600,
                );
              },
            ),
            
            const SizedBox(height: 32),

            // 2. APPOINTMENT PIE CHART (The new "Brain")
            const Text(
              "Appointment Efficiency",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildAppointmentPieChart(),

            const SizedBox(height: 32),

            // 3. CRITICAL INVENTORY ALERTS
            const Text(
              "Critical Stock Alerts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildInventoryAlerts(),
          ],
        ),
      ),
    );
  }

  // --- REIMAGINED STAT ITEM (Antigravity Style) ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- PIE CHART SECTION (fl_chart: ^0.70.0) ---
  Widget _buildAppointmentPieChart() {
    return StreamBuilder<List<Appointment>>(
      stream: _db.getAppointments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        
        final apps = snapshot.data!;
        if (apps.isEmpty) return const Center(child: Text("No data to visualize."));

        double confirmed = apps.where((a) => a.status == 'Confirmed').length.toDouble();
        double pending = apps.where((a) => a.status == 'Pending').length.toDouble();
        double cancelled = apps.where((a) => a.status == 'Cancelled').length.toDouble();

        return SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  value: confirmed,
                  title: '${confirmed.toInt()}',
                  color: Colors.green.shade400,
                  radius: 40,
                  titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: pending,
                  title: '${pending.toInt()}',
                  color: Colors.orange.shade400,
                  radius: 40,
                  titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: cancelled,
                  title: '${cancelled.toInt()}',
                  color: Colors.red.shade400,
                  radius: 40,
                  titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- INVENTORY HEALTH LIST ---
  Widget _buildInventoryAlerts() {
    return StreamBuilder(
      stream: _db.getInventory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final lowStock = snapshot.data!.docs.where((doc) => doc['quantity'] <= 5).toList();

        if (lowStock.isEmpty) {
          return Card(
            elevation: 0,
            color: Colors.green.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.green, width: 0.5)),
            child: const ListTile(
              leading: Icon(Icons.verified, color: Colors.green),
              title: Text("Inventory health is optimal", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            ),
          );
        }

        return Column(
          children: lowStock.map((doc) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.red.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.withValues(alpha: 0.3))),
            child: ListTile(
              leading: const Icon(Icons.report_problem_rounded, color: Colors.red),
              title: Text(doc['itemName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("Qty: ${doc['quantity']}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
            ),
          )).toList(),
        );
      },
    );
  }
}