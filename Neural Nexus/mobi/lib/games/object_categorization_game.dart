import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/game_session_model.dart';
import '../../services/auth_service.dart';

class ObjectCategorizationGame extends StatefulWidget {
  const ObjectCategorizationGame({super.key});

  @override
  State<ObjectCategorizationGame> createState() => _ObjectCategorizationGameState();
}

class _ObjectCategorizationGameState extends State<ObjectCategorizationGame> {
  int _round = 1;
  int _score = 0;
  bool _finished = false;

  final List<Map<String, dynamic>> _items = [
    {
      'name': 'Fresh Banana',
      'emoji': '🍌',
      'correct_category': 'food',
    },
    {
      'name': 'Woolen Cardigan',
      'emoji': '🧥',
      'correct_category': 'clothes',
    },
    {
      'name': 'Daily Vitamin Tablet',
      'emoji': '💊',
      'correct_category': 'medicine',
    },
    {
      'name': 'Wooden Chair',
      'emoji': '🪑',
      'correct_category': 'household',
    },
  ];

  void _chooseCategory(String category) {
    final cur = _items[_round - 1];
    if (category == cur['correct_category']) {
      _score += 25;
      if (_round < _items.length) {
        setState(() => _round++);
      } else {
        setState(() => _finished = true);
        _saveSession();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Take your time. Think about how we use this item at home.')),
      );
    }
  }

  Future<void> _saveSession() async {
    final patientId = AuthService.instance.patientId ?? 'ifra_01';
    final session = GameSessionModel(
      patientId: patientId,
      gameId: 'object_categorization',
      category: 'pattern',
      level: 1,
      score: _score,
      accuracy: 90.0,
      attempts: 4,
      mistakes: 0,
      responseTimeMs: 1400,
      durationSeconds: 24,
      completed: true,
      offlineCreated: true,
    );
    await DatabaseHelper.instance.insertSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final cur = _items[_round - 1];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Object Categorization', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _finished
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📦', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('All Items Sorted!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Score: $_score points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _round = 1;
                            _score = 0;
                            _finished = false;
                          }),
                          child: const Text('Play Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Text('Item $_round of ${_items.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                    const SizedBox(height: 16),
                    const Text('Which category does this object belong to?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),

                    // Display Current Item
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cur['emoji'] as String, style: const TextStyle(fontSize: 54)),
                          const SizedBox(height: 4),
                          Text(cur['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 4 Large Category Buttons
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.4,
                        children: [
                          _buildCatButton('Food', '🍎', 'food', const Color(0xFFFEE2E2)),
                          _buildCatButton('Clothes', '👕', 'clothes', const Color(0xFFE0F2FE)),
                          _buildCatButton('Medicine', '💊', 'medicine', const Color(0xFFFEF3C7)),
                          _buildCatButton('Household', '🪑', 'household', const Color(0xFFDCFCE7)),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCatButton(String title, String emoji, String catCode, Color bgColor) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _chooseCategory(catCode),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ),
    );
  }
}
