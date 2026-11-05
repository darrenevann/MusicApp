import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Song>> _songsFuture;
  final TextEditingController _searchController = TextEditingController(text: 'Pop');
  final Set<int> _favoriteSongIds = {};

  @override
  void initState() {
    super.initState();
    _loadSongs('Pop');
  }

  void _loadSongs(String query) {
    setState(() {
      _songsFuture = ApiService.fetchSongs(query.isEmpty ? 'Pop' : query);
    });
  }

  void _toggleFavorite(int songId) {
    setState(() {
      if (_favoriteSongIds.contains(songId)) {
        _favoriteSongIds.remove(songId);
      } else {
        _favoriteSongIds.add(songId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MusicApp', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Baris Pencarian (Search Bar)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari lagu atau artis...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadSongs('Pop');
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onSubmitted: (value) => _loadSongs(value),
            ),
          ),

          // Daftar Lagu dari API
          Expanded(
            child: FutureBuilder<List<Song>>(
              future: _songsFuture,
              builder: (context, snapshot) {
                // State 1: Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // State 2: Error Handling
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal Memuat Data\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _loadSongs(_searchController.text),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          )
                        ],
                      ),
                    ),
                  );
                }

                // State 3: Data Kosong
                final songs = snapshot.data ?? [];
                if (songs.isEmpty) {
                  return const Center(child: Text('Lagu tidak ditemukan.'));
                }

                // State 4: Sukses Menampilkan List Data
                return RefreshIndicator(
                  onRefresh: () async => _loadSongs(_searchController.text),
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isFav = _favoriteSongIds.contains(song.id);

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            song.coverUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.music_note, size: 50),
                          ),
                        ),
                        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${song.artist} • ${song.album}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : null,
                          ),
                          onPressed: () => _toggleFavorite(song.id),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(song: song),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}