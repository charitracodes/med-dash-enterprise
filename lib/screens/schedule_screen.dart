import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/database_service.dart';
import '../utils/date_formatter.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final DatabaseService _db = DatabaseService();

  void _showAddAppointmentDialog() async {
    final nameCtrl = TextEditingController();
    String selectedStatus = 'Pending';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Schedule Appointment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Patient Name")),
              const SizedBox(height: 15),
              // --- DATE & TIME PICKER BUTTON ---
              ListTile(
                title: Text("Date: ${DateFormatter.formatDateTime(selectedDate)}"),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (pickedTime != null) {
                      setDialogState(() {
                        selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                      });
                    }
                  }
                },
              ),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: ['Pending', 'Confirmed', 'Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  _db.addAppointment(nameCtrl.text, selectedDate, selectedStatus);
                  Navigator.pop(context);
                }
              },
              child: const Text("Schedule"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Schedule"), backgroundColor: Colors.orange.shade800),
      body: StreamBuilder<List<Appointment>>(
        stream: _db.getAppointments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final appointments = snapshot.data!;
          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final app = appointments[index];
              return Card(
                key: ValueKey(app.id),
                child: ListTile(
                  title: Text(app.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormatter.formatDateTime(app.date)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- DELETE BUTTON ---
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _db.deleteAppointment(app.id),
                      ),
                      Chip(label: Text(app.status)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAppointmentDialog,
        backgroundColor: Colors.orange.shade800,
        child: const Icon(Icons.add_task),
      ),
    );
  }
}