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

  void _showAddDialog() {
    final name = TextEditingController();
    final age = TextEditingController();
    final cond = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Register Patient"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
        TextField(controller: age, decoration: const InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
        TextField(controller: cond, decoration: const InputDecoration(labelText: "Condition")),
      ]),
      actions: [ElevatedButton(onPressed: () { _db.addPatient(name.text, int.parse(age.text), cond.text); Navigator.pop(c); }, child: const Text("Save"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Records")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(labelText: "Search by name...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Patient>>(
              stream: _db.getPatients(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final list = snapshot.data!.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final p = list[index];
                    return Dismissible(
                      key: Key(p.id),
                      direction: DismissDirection.endToStart,
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      onDismissed: (d) => _db.deletePatient(p.id),
                      child: Card(child: ListTile(title: Text(p.name), subtitle: Text(p.condition), trailing: Text("${p.age} yrs"))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.person_add)),
    );
  }
}