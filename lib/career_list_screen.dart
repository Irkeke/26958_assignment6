import 'package:flutter/material.dart';
import 'career_record.dart';
import 'career_form_screen.dart';

class CareerListScreen extends StatefulWidget {
  const CareerListScreen({super.key});

  @override
  State<CareerListScreen> createState() => _CareerListScreenState();
}

class _CareerListScreenState extends State<CareerListScreen> {
  Future<void> _delete(
    BuildContext context,
    CareerRecord career,
  ) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this career?'),
        content: Text(career.careerTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (sure == true) {
      await myCareerRecords().doc(career.id).delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Career deleted successfully!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Careers'),
      ),
      body: StreamBuilder(
        stream: myCareerRecords().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final careers = snapshot.data!.docs
              .map((doc) => CareerRecord.fromDoc(doc))
              .toList();

          if (careers.isEmpty) {
            return const Center(
              child: Text('No saved careers yet.'),
            );
          }

          return ListView.builder(
            itemCount: careers.length,
            itemBuilder: (context, index) {
              final career = careers[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: Text(career.careerTitle),
                  subtitle: Text(career.category),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CareerFormScreen(
                        careerRecord: career,
                      ),
                    ),
                  ),
                  onLongPress: () => _delete(context, career),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CareerFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
