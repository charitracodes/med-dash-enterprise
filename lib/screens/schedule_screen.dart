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

  // --- LOGIC: CHECK IF APPOINTMENT IS LOCKED (48 HOUR RULE) ---
  bool _canEditStatus(DateTime appointmentDate) {
    final now = DateTime.now();
    final difference = appointmentDate.difference(now);
    // Returns true only if the appointment is more than 48 hours away
    return difference.inHours >= 48;
  }

  // --- UI: STATUS COLORS ---
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed': return Colors.green.shade600;
      case 'Cancelled': return Colors.red.shade600;
      default: return Colors.orange.shade700;
    }
  }

  // --- DIALOG: CHANGE STATUS (ONLY FOR UNLOCKED SLOTS) ---
  void _showStatusChangeDialog(Appointment app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Status"),
        content: const Text("Select the new status for this appointment:"),
        actions: ['Pending', 'Confirmed', 'Cancelled'].map((status) {
          return TextButton(
            onPressed: () {
              _db.updateAppointmentStatus(app.id, status);
              Navigator.pop(context);
            },
            child: Text(status),
          );
        }).toList(),
      ),
    );
  }

  // --- DIALOG: SCHEDULE NEW APPOINTMENT ---
  void _showAddAppointmentDialog() async {
    final nameCtrl = TextEditingController();
    String selectedStatus = 'Pending';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text("Schedule Appointment"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Patient Name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 15),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  title: Text(DateFormatter.formatDateTime(selectedDate)),
                  leading: const Icon(Icons.calendar_month, color: Colors.blue),
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
                          selectedDate = DateTime(
                            pickedDate.year, pickedDate.month, pickedDate.day,
                            pickedTime.hour, pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: "Initial Status"),
                  items: ['Pending', 'Confirmed', 'Cancelled']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedStatus = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            FilledButton(
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
      appBar: AppBar(
        title: const Text("Appointment Schedule"),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _db.getAppointments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final appointments = snapshot.data!;

          if (appointments.isEmpty) {
            return const Center(child: Text("No appointments scheduled."));
          }

          return ListView.builder(
            itemCount: appointments.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final app = appointments[index];
              final isEditable = _canEditStatus(app.date);

              return Card(
                key: ValueKey(app.id),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(app.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormatter.formatDateTime(app.date)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // DELETE BUTTON WITH CONFIRMATION
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text("Remove Appointment?"),
                              content: const Text("This action cannot be undone."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("No")),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete")),
                              ],
                            ),
                          );
                          if (confirm == true) _db.deleteAppointment(app.id);
                        },
                      ),
                      // TAPPABLE STATUS CHIP
                      GestureDetector(
                        onTap: () {
                          if (isEditable) {
                            _showStatusChangeDialog(app);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Changes locked (Less than 48h remaining)"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: Chip(
                          label: Text(
                            app.status,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: _getStatusColor(app.status),
                          side: BorderSide.none,
                          avatar: !isEditable ? const Icon(Icons.lock, size: 14, color: Colors.white) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAppointmentDialog,
        backgroundColor: Colors.orange.shade800,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text("New Slot", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}