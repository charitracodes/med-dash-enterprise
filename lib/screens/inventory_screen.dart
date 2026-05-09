import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  static final DatabaseService _db = DatabaseService();

  // --- LOGIC: STATUS COLOR FOR STOCK LEVELS ---
  Color _getQtyColor(int qty) {
    if (qty <= 0) return Colors.red;
    if (qty <= 5) return Colors.orange; // Low stock warning
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Records"),
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.getInventory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(colorScheme);
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var item = items[index];
              var data = item.data() as Map<String, dynamic>;
              
              // We use camelCase keys here to match our DatabaseService update
              String itemName = data['itemName'] ?? 'Unknown Item';
              int qty = data['quantity'] ?? 0;

              return Card(
                key: ValueKey(item.id),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: _getQtyColor(qty).withValues(alpha: 0.1),
                    child: Icon(Icons.medication, color: _getQtyColor(qty)),
                  ),
                  title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    qty <= 5 ? "⚠️ Low Stock: $qty" : "In Stock: $qty",
                    style: TextStyle(
                      color: qty <= 5 ? Colors.orange.shade900 : Colors.grey.shade600,
                      fontWeight: qty <= 5 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // UPDATE STOCK BUTTON
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.blue),
                        onPressed: () => _showUpdateDialog(context, item.id, itemName, qty),
                      ),
                      // DELETE BUTTON WITH CONFIRMATION
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final confirm = await _showDeleteConfirm(context, itemName);
                          if (confirm == true) _db.deleteInventoryItem(item.id);
                        },
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
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box),
        label: const Text("New Item"),
      ),
    );
  }

  // --- UI: EMPTY STATE ---
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          const Text("Inventory is Empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Add medicines or supplies to track them.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- DIALOG: ADD NEW ITEM ---
  void _showAddDialog(BuildContext context) {
    final name = TextEditingController();
    final qty = TextEditingController();
    
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Add New Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Item Name", prefixIcon: Icon(Icons.label_outline))),
            const SizedBox(height: 8),
            TextField(controller: qty, decoration: const InputDecoration(labelText: "Initial Quantity", prefixIcon: Icon(Icons.numbers)), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              if (name.text.isNotEmpty && qty.text.isNotEmpty) {
                _db.addInventoryItem(name.text, int.parse(qty.text));
                Navigator.pop(c);
              }
            },
            child: const Text("Save Item"),
          ),
        ],
      ),
    );
  }

  // --- DIALOG: UPDATE STOCK QUANTITY ---
  void _showUpdateDialog(BuildContext context, String id, String name, int currentQty) {
    final qtyController = TextEditingController(text: currentQty.toString());
    
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("Update $name"),
        content: TextField(
          controller: qtyController,
          decoration: const InputDecoration(labelText: "New Quantity"),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _db.updateStock(id, int.parse(qtyController.text));
              Navigator.pop(c);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // --- DIALOG: DELETE CONFIRMATION ---
  Future<bool?> _showDeleteConfirm(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text("Are you sure you want to remove $name from inventory?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete")),
        ],
      ),
    );
  }
}