import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CareerRecord {
  // Sample career records, written once when a new account is created

  Future<void> addSampleCareerRecords() async {
    final samples = [
      CareerRecord(
        careerTitle: 'Software Developer',
        description: 'Designs, develops and maintains software applications.',
        category: 'Technology',
      ),
      CareerRecord(
        careerTitle: 'Data Analyst',
        description:
            'Collects, analyzes and interprets data to support decisions.',
        category: 'Data and Analytics',
      ),
      CareerRecord(
        careerTitle: 'Cybersecurity Analyst',
        description:
            'Protects computer systems and networks from cyber threats.',
        category: 'Cybersecurity',
      ),
      CareerRecord(
        careerTitle: 'UI/UX Designer',
        description:
            'Designs user-friendly and attractive digital experiences.',
        category: 'Design',
      ),
      CareerRecord(
        careerTitle: 'Project Manager',
        description: 'Plans, organizes and manages projects to achieve goals.',
        category: 'Business',
      ),
    ];

    final batch = FirebaseFirestore.instance.batch();

    for (final career in samples) {
      batch.set(myCareerRecords().doc(), {
        ...career.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  CareerRecord({
    this.id = '',
    required this.careerTitle,
    required this.description,
    required this.category,
    this.createdAt,
  });

  final String id;
  final String careerTitle;
  final String description;
  final String category;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'careerTitle': careerTitle,
        'description': description,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory CareerRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return CareerRecord(
      id: doc.id,
      careerTitle: data['careerTitle'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// The signed-in user's career records:
// users/{uid}/careerRecords

CollectionReference<Map<String, dynamic>> myCareerRecords() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw StateError('Please sign in to access career records.');
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('careerRecords');
}
