import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'career.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _delete(BuildContext context, Career career) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this career?'),
        content: Text(career.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (sure == true) {
      await myCareers().doc(career.id).delete();
    }
  }

  void _openForm(BuildContext context, {Career? career}) {
    showDialog(
      context: context,
      builder: (_) => _CareerDialog(career: career),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Path Explorer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: myCareers().orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load your careers.\n${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final careers = snapshot.data!.docs.map(Career.fromDoc).toList();

          if (careers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No careers saved yet.\nTap + to add your first one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Computed from the saved data, never saved itself
          final fields = careers.map((c) => c.field).toSet().length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${careers.length} careers saved across $fields fields',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: careers.length,
                  itemBuilder: (context, i) {
                    final c = careers[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(c.title),
                        subtitle: Text(c.notes.isEmpty
                            ? c.field
                            : '${c.field} • ${c.notes}'),
                        onTap: () => _openForm(context, career: c),
                        onLongPress: () => _delete(context, c),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Tap to edit · Long press to delete',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CareerDialog extends StatefulWidget {
  const _CareerDialog({this.career});
  final Career? career;

  @override
  State<_CareerDialog> createState() => _CareerDialogState();
}

class _CareerDialogState extends State<_CareerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.career?.title ?? '');
  late final _field = TextEditingController(text: widget.career?.field ?? '');
  late final _notes = TextEditingController(text: widget.career?.notes ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _field.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final career = Career(
      title: _title.text.trim(),
      field: _field.text.trim(),
      notes: _notes.text.trim(),
    );
    try {
      if (widget.career == null) {
        await myCareers().add({
          ...career.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await myCareers().doc(widget.career!.id).update(career.toMap());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.career != null;
    return AlertDialog(
      title: Text(editing ? 'Edit career' : 'Add a career'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Career title'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a title' : null,
              ),
              TextFormField(
                controller: _field,
                decoration:
                    const InputDecoration(labelText: 'Field (e.g. Tech)'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a field' : null,
              ),
              TextFormField(
                controller: _notes,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(editing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
