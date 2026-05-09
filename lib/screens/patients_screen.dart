import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../services/database_service.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = "";

  // 1. ADD PATIENT LOGIC WITH VALIDATION
  void _showAddDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final conditionController = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Register Patient"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: "Age",
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: conditionController,
              decoration: const InputDecoration(
                labelText: "Condition",
                prefixIcon: Icon(Icons.medical_information_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              // Validation Logic
              if (nameController.text.trim().isEmpty) {
                _showSnackBar("Full Name is required", Colors.redAccent);
                return;
              }
              int? parsedAge = int.tryParse(ageController.text);
              if (parsedAge == null || parsedAge <= 0) {
                _showSnackBar("Please enter a valid age", Colors.orangeAccent);
                return;
              }

              _db.addPatient(
                nameController.text.trim(),
                parsedAge,
                conditionController.text.trim(),
              );
              Navigator.pop(c);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Records"),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              hintText: "Search by name...",
              leading: const Icon(Icons.search),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // LIST AREA
          Expanded(
            child: StreamBuilder<List<Patient>>(
              stream: _db.getPatients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(colorScheme);
                }

                final list = snapshot.data!
                    .where((p) => p.name.toLowerCase().contains(_searchQuery))
                    .toList();

                if (list.isEmpty) {
                  return const Center(child: Text("No matches found."));
                }

                return ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemBuilder: (context, index) {
                    final p = list[index];
                    return _buildDismissibleCard(p, colorScheme);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("New Patient"),
      ),
    );
  }

  // 2. EMPTY STATE UI
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Patient Records Found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Tap 'New Patient' to register someone.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 3. DELETE CONFIRMATION & CARD UI
  Widget _buildDismissibleCard(Patient p, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(p.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Confirm Delete"),
                content: Text(
                  "Delete ${p.name}'s record? This cannot be undone.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Delete"),
                  ),
                ],
              );
            },
          );
        },
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
        ),
        onDismissed: (direction) => _db.deletePatient(p.id),
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(p.name[0].toUpperCase()),
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(p.condition),
            trailing: Text(
              "${p.age} yrs",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}