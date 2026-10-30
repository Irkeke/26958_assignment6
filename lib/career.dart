import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Career {
  Career({
    this.id = '',
    required this.title,
    required this.field,
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String field;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'title': title,
        'field': field,
        'notes': notes,
      };

  factory Career.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Career(
      id: doc.id,
      title: data['title'] as String? ?? '',
      field: data['field'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// The signed-in user's careers: users/{uid}/careers
CollectionReference<Map<String, dynamic>> myCareers() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('careers');
}
