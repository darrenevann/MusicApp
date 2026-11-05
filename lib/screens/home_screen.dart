import 'package:flutter/material.dart';
import '../main.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  late Future<List<Song>> _songsFuture;
  String _currentQuery = 'pop';
  
  final List<String> _categories = ['Pop', 'Rock', 'Jazz', 'Anime', 'Hip-Hop'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Mengambil data dari API
  void _fetchData() {
    setState(() {
      _songsFuture = _apiService.fetchSongs(_currentQuery);
    });
  }

  // Menangani input pencarian
  void _handleSearch(String query) {
    if (query.isNotEmpty) {
      _currentQuery = query;
      _searchController.text = query;
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Variabel warna adaptif untuk estetika Dark Mode Neo-Brutalism
    final themeBorder = isDark ? Colors.white : Colors.black;
    final themeShadow = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFDE59),
        elevation: 0,
        title: const Text(
          'NEO MUSIC',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: Colors.black, height: 4.0), // Garis bawah AppBar tetap hitam
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.black),
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border.all(color: themeBorder, width: 3),
                boxShadow: [BoxShadow(color: themeShadow, offset: const Offset(4, 4))],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Cari lagu atau artis...',
                  hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black),
                    onPressed: () => _handleSearch(_searchController.text),
                  ),
                ),
                onSubmitted: _handleSearch,
              ),
            ),
          ),
          
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _currentQuery.toLowerCase() == category.toLowerCase();
                
                return GestureDetector(
                  onTap: () => _handleSearch(category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00E5FF) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      border: Border.all(color: isSelected ? Colors.black : themeBorder, width: 2),
                      boxShadow: isSelected 
                        ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))] 
                        : null,
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // List Data Lagu
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchData(),
              color: Colors.black,
              backgroundColor: const Color(0xFFFFDE59),
              child: FutureBuilder<List<Song>>(
                future: _songsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.black));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontWeight: FontWeight.bold)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Data tidak ditemukan.', style: TextStyle(fontWeight: FontWeight.bold)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _buildNeoCard(snapshot.data![index], context, isDark);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI List Item (Song Card)
  Widget _buildNeoCard(Song song, BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(song: song))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF66A1), // Neon Pink tetap menyala di Dark Mode
          border: Border.all(color: isDark ? Colors.white : Colors.black, width: 3),
          boxShadow: [
            BoxShadow(color: isDark ? Colors.white : Colors.black, offset: const Offset(4, 4)),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          leading: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
            child: Image.network(song.artworkUrl, width: 50, height: 50, fit: BoxFit.cover),
          ),
          title: Text(
            song.trackName,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black), // Teks tetap hitam
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(song.artistName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.play_circle_filled, color: Colors.black, size: 32),
        ),
      ),
    );
  }
}