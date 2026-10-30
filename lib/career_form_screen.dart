import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'career_record.dart';

class CareerFormScreen extends StatefulWidget {
  final CareerRecord? careerRecord;

  const CareerFormScreen({
    super.key,
    this.careerRecord,
  });

  @override
  State<CareerFormScreen> createState() => _CareerFormScreenState();
}

class _CareerFormScreenState extends State<CareerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.careerRecord != null) {
      _titleController.text = widget.careerRecord!.careerTitle;
      _descriptionController.text = widget.careerRecord!.description;
      _categoryController.text = widget.careerRecord!.category;
    }
  }

  Future<void> _saveCareer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final careerRecord = CareerRecord(
      careerTitle: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
    );

    try {
      if (widget.careerRecord == null) {
        await myCareerRecords().add({
          ...careerRecord.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await myCareerRecords().doc(widget.careerRecord!.id).update({
          'careerTitle': careerRecord.careerTitle,
          'description': careerRecord.description,
          'category': careerRecord.category,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Career saved successfully!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving career: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.careerRecord == null ? 'Add Career' : 'Edit Career',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Career Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Career Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a career title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Career Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Career Category',
                  hintText: 'Example: Technology, Business, Health',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a career category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveCareer,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.careerRecord == null
                            ? 'Save Career'
                            : 'Update Career',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
