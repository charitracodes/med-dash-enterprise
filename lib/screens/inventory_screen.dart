import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  static final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Records"), backgroundColor: Colors.teal),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.getInventory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!.docs;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              int qty = item['quantity'] ?? 0;
              return Card(
                key: ValueKey(item.id), // Critical fix for 4GB RAM list reconciliation
                child: ListTile(
                  title: Text(item['item name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("In Stock: $qty"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_note, color: Colors.blue), onPressed: () => {}), // Placeholder for update
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _db.deleteInventoryItem(item.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add_box, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final name = TextEditingController();
    final qty = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Add New Item"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: "Item Name")),
        TextField(controller: qty, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
      ]),
      actions: [ElevatedButton(onPressed: () { _db.addInventoryItem(name.text, int.parse(qty.text)); Navigator.pop(c); }, child: const Text("Save"))],
    ));
  }
}