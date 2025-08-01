// lib/screens/home_screen.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:racketlog/screens/match_screen.dart';
import 'package:racketlog/screens/schedule_match_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// WIDGET BARU UNTUK KUTIPAN
class QuoteCard extends StatelessWidget {
  final String quote;
  final String author;
  final bool isLoading;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.author,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else ...[
              Text(
                '"$quote"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '- $author',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _quoteText = "Memuat motivasi...";
  String _quoteAuthor = " ";
  bool _isQuoteLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchQuote();
  }

  // FUNGSI BARU UNTUK MENGAMBIL DATA DARI JSON SERVER
  Future<void> _fetchQuote() async {
    // PENTING: Ganti URL jika menggunakan Android Emulator
    // Gunakan 'http://10.0.2.2:3000/quotes' untuk Android Emulator
    // Gunakan 'http://localhost:3000/quotes' untuk Web/Desktop/iOS Simulator
    final url = 'http://localhost:3000/quotes';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> quotes = json.decode(response.body);
        if (quotes.isNotEmpty) {
          final randomQuote = quotes[Random().nextInt(quotes.length)];
          setState(() {
            _quoteText = randomQuote['text'];
            _quoteAuthor = randomQuote['author'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _quoteText = "Gagal memuat motivasi. Pastikan JSON server berjalan.";
        _quoteAuthor = "Error";
      });
    } finally {
      setState(() {
        _isQuoteLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RacketLog'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Column(
        children: [
          // MENAMPILKAN KUTIPAN DI SINI
          QuoteCard(
            quote: _quoteText,
            author: _quoteAuthor,
            isLoading: _isQuoteLoading,
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.history), text: 'Riwayat'),
              Tab(icon: Icon(Icons.event), text: 'Jadwal'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                HistoryView(),
                ScheduleView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScheduleMatchScreen()),
          );
        },
        tooltip: 'Jadwalkan Pertandingan',
        child: const Icon(Icons.add_alarm),
      ),
    );
  }
}

// Widget HistoryView (tidak ada perubahan)
class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('userId', isEqualTo: user?.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada riwayat pertandingan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final matches = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index].data() as Map<String, dynamic>;
            final winnerName = match['winnerName'] ?? 'N/A';
            final score = '${match['player1GamesWon']} - ${match['player2GamesWon']}';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.sports_tennis, color: Colors.green),
                title: Text('${match['player1Name']} vs ${match['player2Name']}'),
                subtitle: Text('Pemenang: $winnerName ($score)'),
              ),
            );
          },
        );
      },
    );
  }
}

// Widget ScheduleView (tidak ada perubahan)
class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  void _deleteSchedule(String docId) {
    FirebaseFirestore.instance.collection('scheduled_matches').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    initializeDateFormatting('id_ID', null);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('scheduled_matches')
          .where('userId', isEqualTo: user?.uid)
          .orderBy('matchDateTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada jadwal pertandingan.\nTekan tombol + untuk membuat jadwal baru.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final schedules = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index].data() as Map<String, dynamic>;
            final docId = schedules[index].id;
            final matchDateTime = (schedule['matchDateTime'] as Timestamp).toDate();

            final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(matchDateTime);
            final formattedTime = DateFormat('HH:mm').format(matchDateTime);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.event_note, color: Colors.blue),
                title: Text('${schedule['player1Name']} vs ${schedule['player2Name']}'),
                subtitle: Text('$formattedDate - $formattedTime WIB'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _deleteSchedule(docId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchScreen(
                              player1Name: schedule['player1Name'],
                              player2Name: schedule['player2Name'],
                            ),
                          ),
                        );
                      },
                      child: const Text('Mulai'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteSchedule(docId),
                      tooltip: 'Hapus Jadwal',
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}