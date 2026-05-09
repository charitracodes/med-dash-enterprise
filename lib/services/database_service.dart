import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';
import '../models/appointment_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Helper to get the current logged-in User ID
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ==========================
  //        PATIENTS SECTION
  // ==========================

  // Streams only the patients belonging to the current user
  Stream<List<Patient>> getPatients() {
    return _db
        .collection('patients')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList());
  }

  Future<void> addPatient(String name, int age, String condition) {
    return _db.collection('patients').add({
      'name': name, // Changed to 'name' to match typical model naming
      'age': age,
      'condition': condition,
      'userId': uid,
    });
  }

  Future<void> deletePatient(String id) {
    return _db.collection('patients').doc(id).delete();
  }

  // ==========================
  //     APPOINTMENTS SECTION
  // ==========================

  Stream<List<Appointment>> getAppointments() {
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList());
  }

  Future<void> addAppointment(String name, DateTime date, String status) {
    return _db.collection('appointments').add({
      'patientName': name, // Changed to camelCase for consistency
      'date': Timestamp.fromDate(date),
      'status': status,
      'userId': uid,
    });
  }

  // FIXED: This is now correctly inside the class and unified
  Future<void> updateAppointmentStatus(String id, String newStatus) async {
    return await _db.collection('appointments').doc(id).update({
      'status': newStatus,
    });
  }

  Future<void> deleteAppointment(String id) {
    return _db.collection('appointments').doc(id).delete();
  }

  // ==========================
  //      INVENTORY SECTION
  // ==========================

  Stream<QuerySnapshot> getInventory() {
    return _db
        .collection('inventory')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addInventoryItem(String name, int quantity) {
    return _db.collection('inventory').add({
      'itemName': name,
      'quantity': quantity,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': uid,
    });
  }

  Future<void> updateStock(String id, int newQuantity) {
    return _db.collection('inventory').doc(id).update({
      'quantity': newQuantity,
    });
  }

  Future<void> deleteInventoryItem(String id) {
    return _db.collection('inventory').doc(id).delete();
  }
} // <--- FINAL CLASS BRACKET (Nothing should be below this)