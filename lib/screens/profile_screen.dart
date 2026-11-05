import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Darren Evan Nathanael',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Mahasiswa Sistem Informasi',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Card Detail Informasi
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.school, color: Colors.blueAccent),
                    title: Text('Universitas'),
                    subtitle: Text('Universitas Tarumanagara'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.assignment_ind, color: Colors.blueAccent),
                    title: Text('Program Studi'),
                    subtitle: Text('Sistem Informasi - Semester 5'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.code, color: Colors.blueAccent),
                    title: Text('Mata Kuliah'),
                    subtitle: Text('Pemrograman Mobil (Tugas 5)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}