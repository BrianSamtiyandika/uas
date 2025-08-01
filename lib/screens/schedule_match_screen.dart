// lib/screens/schedule_match_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ScheduleMatchScreen extends StatefulWidget {
  const ScheduleMatchScreen({super.key});

  @override
  State<ScheduleMatchScreen> createState() => _ScheduleMatchScreenState();
}

class _ScheduleMatchScreenState extends State<ScheduleMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _player1Controller = TextEditingController(text: 'Pemain 1');
  final _player2Controller = TextEditingController(text: 'Pemain 2');
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap pilih tanggal dan waktu pertandingan.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User tidak ditemukan.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final matchDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      try {
        await FirebaseFirestore.instance.collection('scheduled_matches').add({
          'userId': user.uid,
          'player1Name': _player1Controller.text,
          'player2Name': _player2Controller.text,
          'matchDateTime': Timestamp.fromDate(matchDateTime),
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pertandingan berhasil dijadwalkan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan jadwal: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwalkan Pertandingan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _player1Controller,
                decoration: const InputDecoration(labelText: 'Nama Pemain 1'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama pemain 1 tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _player2Controller,
                decoration: const InputDecoration(labelText: 'Nama Pemain 2'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama pemain 2 tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Pilih Tanggal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: const Text('Pilih Waktu'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedDate != null && _selectedTime != null)
                Center(
                  child: Text(
                    'Jadwal: ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate!)} - ${_selectedTime!.format(context)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _saveSchedule,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Jadwalkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}