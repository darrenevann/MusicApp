import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final Future<void> Function(String) onSave;
  final Future<void> Function(bool) onThemeChanged;

  const ProfilePage({
    super.key,
    required this.username,
    required this.isDarkMode,
    required this.onSave,
    required this.onThemeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.username);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Icon(Icons.account_circle, size: 100),
            const SizedBox(height: 16),
            Text(
              widget.username.isEmpty
                  ? 'Selamat Datang!'
                  : 'Halo, ${widget.username}!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nama Pengguna',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama tidak boleh kosong')),
                  );
                  return;
                }

                await widget.onSave(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama berhasil disimpan')),
                  );
                }
              },
              child: const Text('Simpan Nama'),
            ),
            const SizedBox(height: 32),
            SwitchListTile(
              title: const Text(
                'Mode Gelap',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                widget.isDarkMode ? 'Tema Gelap (Hitam)' : 'Tema Terang (Putih)',
              ),
              secondary: Icon(
                widget.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              ),
              value: widget.isDarkMode,
              onChanged: (bool value) async {
                await widget.onThemeChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}