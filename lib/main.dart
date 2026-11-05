import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'detail_page.dart';
import 'profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Box settingsBox;
  String username = '';
  bool isDarkMode = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    loadData();
  }

  void loadData() {
    setState(() {
      username = settingsBox.get('username', defaultValue: '');
      isDarkMode = settingsBox.get('isDarkMode', defaultValue: true);
      isLoading = false;
    });
  }

  Future<void> saveUsername(String name) async {
    await settingsBox.put('username', name);
    setState(() => username = name);
  }

  Future<void> saveTheme(bool isDark) async {
    await settingsBox.put('isDarkMode', isDark);
    setState(() => isDarkMode = isDark);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        primaryColor: const Color(0xFF6C5CE7),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        primaryColor: const Color(0xFF6C5CE7),
      ),
      home: MainMusicScreen(
        username: username,
        isDarkMode: isDarkMode,
        onSaveUsername: saveUsername,
        onThemeChanged: saveTheme,
      ),
    );
  }
}

class MainMusicScreen extends StatefulWidget {
  final String username;
  final bool isDarkMode;
  final Future<void> Function(String) onSaveUsername;
  final Future<void> Function(bool) onThemeChanged;

  const MainMusicScreen({
    super.key,
    required this.username,
    required this.isDarkMode,
    required this.onSaveUsername,
    required this.onThemeChanged,
  });

  @override
  State<MainMusicScreen> createState() => _MainMusicScreenState();
}

class _MainMusicScreenState extends State<MainMusicScreen> {
  final controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List songs = [];
  Map<String, dynamic>? currentSong;
  String? currentlyPlayingUrl;
  bool isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> cariLagu() async {
    if (controller.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    final url = Uri.https('itunes.apple.com', '/search', {'term': controller.text, 'entity': 'song', 'limit': '15'});
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() => songs = jsonDecode(res.body)['results'] ?? []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> playAudio(Map<String, dynamic> song) async {
    final url = song['previewUrl'];
    if (url == null || url.isEmpty) return;

    if (currentlyPlayingUrl == url && isPlaying) {
      await _audioPlayer.pause();
      setState(() => isPlaying = false);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        currentSong = song;
        currentlyPlayingUrl = url;
        isPlaying = true;
      });
    }
  }

  Future<void> togglePausePlay() async {
    if (currentlyPlayingUrl == null) return;
    isPlaying ? await _audioPlayer.pause() : await _audioPlayer.resume();
    setState(() => isPlaying = !isPlaying);
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      isPlaying = false;
      currentlyPlayingUrl = null;
      currentSong = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.username.isEmpty ? 'Explore Music' : 'Halo, ${widget.username}!',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text('Cari lagu favoritmu dan nikmati musiknya', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ],
                        ),
                        IconButton(
                          icon: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(
                                  username: widget.username,
                                  isDarkMode: widget.isDarkMode,
                                  onSave: widget.onSaveUsername,
                                  onThemeChanged: widget.onThemeChanged,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Cari judul lagu atau artis...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(icon: const Icon(Icons.send_rounded), onPressed: cariLagu),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onSubmitted: (_) => cariLagu(),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: songs.isEmpty
                          ? Center(child: Text('Belum ada lagu yang dicari', style: TextStyle(color: Colors.grey.shade500)))
                          : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: songs.length,
                        itemBuilder: (context, i) {
                          final song = songs[i];
                          final isThisPlaying = isPlaying && currentlyPlayingUrl == song['previewUrl'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  song['artworkUrl60'] ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.music_note),
                                ),
                              ),
                              title: Text(song['trackName'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(song['artistName'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: Icon(isThisPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: primary, size: 36),
                                onPressed: () => playAudio(song),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPage(
                                      song: song,
                                      audioPlayer: _audioPlayer,
                                      isPlaying: isThisPlaying,
                                      onPlayToggle: () => playAudio(song),
                                      onStopAudio: stopAudio,
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (currentSong != null)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailPage(
                      song: currentSong!,
                      audioPlayer: _audioPlayer,
                      isPlaying: isPlaying,
                      onPlayToggle: () => playAudio(currentSong!),
                      onStopAudio: stopAudio,
                    ),
                  ),
                ).then((_) => setState(() {})),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          currentSong!['artworkUrl60'] ?? '',
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.music_note),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currentSong!['trackName'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(currentSong!['artistName'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 36), onPressed: togglePausePlay),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}