import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String name;
  final int age;
  final String condition;

  Patient({required this.id, required this.name, required this.age, required this.condition});

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Patient(
      id: doc.id,
      name: data['patient'] ?? 'Unknown',
      age: data['age'] ?? 0,
      condition: data['condition'] ?? 'No condition specified',
    );
  }
}