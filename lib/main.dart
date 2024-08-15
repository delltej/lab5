import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokémon Cards',
      theme: ThemeData(
        primarySwatch: Colors.teal, // Updated color scheme
        scaffoldBackgroundColor: Colors.grey[100], // Slightly lighter background color
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PokemonListScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/splash.jpg',
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  _PokemonListScreenState createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  List<dynamic> pokemonCards = [];
  List<dynamic> filteredCards = [];
  List<dynamic> randomCards = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchPokemonCards();
  }

  Future<void> fetchPokemonCards() async {
    final dio = Dio();
    final response = await dio.get(
        'https://api.pokemontcg.io/v2/cards?q=name:gardevoir');

    setState(() {
      pokemonCards = response.data['data'];
      filteredCards = pokemonCards;
      randomCards = getRandomCards(); // Get five random cards
      isLoading = false;
    });
  }

  List<dynamic> getRandomCards() {
    final random = Random();
    final randomSet = <dynamic>{};
    while (randomSet.length < 5 && pokemonCards.length > randomSet.length) {
      randomSet.add(pokemonCards[random.nextInt(pokemonCards.length)]);
    }
    return randomSet.toList();
  }

  void filterCards(String query) {
    setState(() {
      searchQuery = query;
      filteredCards = pokemonCards.where((card) {
        final name = card['name'].toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower);
      }).toList();
    });
  }

  int extractHp(String hpString) {
    final match = RegExp(r'(\d+)').firstMatch(hpString);
    return match != null ? int.tryParse(match.group(0) ?? '0') ?? 0 : 0;
  }

  void showImageDialog(String imageUrl, String winnerText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                  minScale: 0.1,
                  maxScale: 4.0,
                ),
                const SizedBox(height: 16.0),
                Text(
                  winnerText,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        );
      },
    );
  }

  void selectWinner() {
    if (randomCards.isEmpty) return;

    dynamic winnerCard;
    int maxHp = 0;

    for (final card in randomCards) {
      final hp = card['hp'] != null ? extractHp(card['hp']) : 0;
      if (hp > maxHp) {
        maxHp = hp;
        winnerCard = card;
      }
    }

    if (winnerCard != null) {
      showImageDialog(winnerCard['images']['large'], 'Winner card with HP: $maxHp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal, // Set the AppBar color to teal
        title: const Text(
          'Pokémon Cards',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: filterCards,
              decoration: InputDecoration(
                hintText: 'Search Pokémon...',
                hintStyle: const TextStyle(fontWeight: FontWeight.normal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                fillColor: Colors.white, // Set background color to white
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: randomCards.length,
                    itemBuilder: (context, index) {
                      final card = randomCards[index];
                      return Container(
                        color: index.isEven ? Colors.white : Colors.teal[50], // Alternate row colors
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          elevation: 4.0,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            leading: SizedBox(
                              width: 60, // Reduced size to 60
                              height: 60, // Reduced size to 60
                              child: Image.network(card['images']['small'], fit: BoxFit.cover),
                            ),
                            title: Text(
                              card['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold), // Make text bold
                            ),
                            onTap: () {
                              showImageDialog(card['images']['large'], '');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: selectWinner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Set button color to teal
                      foregroundColor: Colors.white, // Set button text color to white
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                    ),
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
    );
  }
}
