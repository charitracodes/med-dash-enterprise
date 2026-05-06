import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientName;
  final DateTime date;
  final String status;

  Appointment({required this.id, required this.patientName, required this.date, required this.status});

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientName: data['patient name'] ?? 'Unknown',
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'Pending',
    );
  }
}