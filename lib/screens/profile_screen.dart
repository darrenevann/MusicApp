import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF66A1), // Pink
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'PROFILE',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: Colors.black, height: 4.0),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF),
              border: Border.all(color: Colors.black, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(8, 8)),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Profil Pengguna
                Icon(Icons.terminal, size: 80, color: Colors.black),
                SizedBox(height: 16),
                Text(
                  'Darren Evan Nathanael',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Information Systems',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Divider(color: Colors.black, thickness: 2),
                SizedBox(height: 16),
                Text(
                  'GitHub: darrenevann',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}