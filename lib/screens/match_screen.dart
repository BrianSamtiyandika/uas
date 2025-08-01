// lib/screens/match_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchScreen extends StatefulWidget {
  // Tambahkan parameter opsional untuk menerima nama pemain
  final String? player1Name;
  final String? player2Name;

  const MatchScreen({
    super.key,
    this.player1Name,
    this.player2Name,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final TextEditingController _player1NameController = TextEditingController();
  final TextEditingController _player2NameController = TextEditingController();

  int _player1Score = 0;
  int _player2Score = 0;
  int _player1GamesWon = 0;
  int _player2GamesWon = 0;

  String? _matchWinner;
  bool _isMatchStarted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Jika ada nama pemain yang dikirim, gunakan nama tersebut
    if (widget.player1Name != null && widget.player2Name != null) {
      _player1NameController.text = widget.player1Name!;
      _player2NameController.text = widget.player2Name!;
      // Langsung mulai pertandingan jika nama sudah ada
      _isMatchStarted = true;
    } else {
      // Jika tidak, gunakan nama default
      _player1NameController.text = 'Pemain 1';
      _player2NameController.text = 'Pemain 2';
    }
  }

  @override
  void dispose() {
    _player1NameController.dispose();
    _player2NameController.dispose();
    super.dispose();
  }

  void _incrementScore(int playerNumber) {
    if (_matchWinner != null) return;
    setState(() {
      if (playerNumber == 1) {
        _player1Score++;
      } else {
        _player2Score++;
      }
      _checkForGameWinner();
    });
  }

  void _checkForGameWinner() {
    bool isPlayer1Winner = false;
    bool isPlayer2Winner = false;

    if (_player1Score >= 21 && _player1Score >= _player2Score + 2) {
      isPlayer1Winner = true;
    } else if (_player2Score >= 21 && _player2Score >= _player1Score + 2) {
      isPlayer2Winner = true;
    } else if (_player1Score == 30 && _player2Score == 29) {
      isPlayer1Winner = true;
    } else if (_player2Score == 30 && _player1Score == 29) {
      isPlayer2Winner = true;
    }

    if (isPlayer1Winner) {
      _handleGameEnd(1);
    } else if (isPlayer2Winner) {
      _handleGameEnd(2);
    }
  }

  void _handleGameEnd(int winningPlayer) {
    setState(() {
      if (winningPlayer == 1) {
        _player1GamesWon++;
      } else {
        _player2GamesWon++;
      }
      if (_player1GamesWon == 2) {
        _matchWinner = _player1NameController.text;
      } else if (_player2GamesWon == 2) {
        _matchWinner = _player2NameController.text;
      }
      if (_matchWinner == null) {
        _resetGameScores();
      } else {
        _showWinnerDialog();
      }
    });
  }

  Future<void> _saveMatchAndExit() async {
    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa menyimpan, user tidak ditemukan.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('matches').add({
        'userId': user.uid,
        'player1Name': _player1NameController.text,
        'player2Name': _player2NameController.text,
        'player1GamesWon': _player1GamesWon,
        'player2GamesWon': _player2GamesWon,
        'winnerName': _matchWinner,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pertandingan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showWinnerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pertandingan Selesai!'),
          content: Text('Selamat, ${_matchWinner ?? "Pemenang"} memenangkan pertandingan!'),
          actions: <Widget>[
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : TextButton(
              onPressed: _saveMatchAndExit,
              child: const Text('Simpan & Keluar'),
            ),
          ],
        );
      },
    );
  }

  void _resetGameScores() {
    setState(() {
      _player1Score = 0;
      _player2Score = 0;
    });
  }

  void _startMatch() {
    setState(() {
      if (_player1NameController.text.isEmpty) _player1NameController.text = 'Pemain 1';
      if (_player2NameController.text.isEmpty) _player2NameController.text = 'Pemain 2';
      _isMatchStarted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Jika nama pemain dikirim, jangan tampilkan setup view, langsung ke match view
    final bool showSetupView = widget.player1Name == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(showSetupView && !_isMatchStarted ? 'Mulai Pertandingan' : 'Skor Pertandingan'),
      ),
      body: _isMatchStarted ? _buildMatchView() : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Masukkan Nama Pemain', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextField(
              controller: _player1NameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pemain 1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _player2NameController,
              decoration: const InputDecoration(
                labelText: 'Nama Pemain 2',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: _startMatch,
              child: const Text('Mulai'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchView() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              const Text('GAMES WON', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(
                '$_player1GamesWon - $_player2GamesWon',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildPlayerColumn(1, _player1NameController.text, _player1Score),
              const VerticalDivider(thickness: 2),
              _buildPlayerColumn(2, _player2NameController.text, _player2Score),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerColumn(int playerNumber, String name, int score) {
    return Expanded(
      child: InkWell(
        onTap: () => _incrementScore(playerNumber),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                '$score',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: _matchWinner != null ? Colors.grey : Theme.of(context).colorScheme.primary,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('POIN'),
                onPressed: () => _incrementScore(playerNumber),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}