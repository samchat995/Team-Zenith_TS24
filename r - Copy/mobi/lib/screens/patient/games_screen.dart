import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../games/memory_match_game.dart';
import '../../games/remember_objects_game.dart';
import '../../games/routine_order_game.dart';
import '../../games/find_different_game.dart';
import '../../games/twin_shapes_game.dart';
import '../../games/pattern_completion_game.dart';
import '../../games/object_categorization_game.dart';
import '../../games/story_recall_game.dart';
import '../../games/emotion_recognition_game.dart';
import '../../games/face_name_memory_game.dart';
import '../../games/location_memory_game.dart';
import '../../games/sound_memory_game.dart';
import '../../games/word_recall_game.dart';
import '../../games/object_recognition_game.dart';
import '../../games/sequence_recall_game.dart';
import '../../games/missing_object_game.dart';
import '../../games/match_pairs_game.dart';
import '../../games/picture_word_match_game.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _allGames = [
    {
      'id': 'remember_objects',
      'title': 'Remember the Objects',
      'category': 'memory',
      'desc': 'View familiar objects, then identify which ones you saw.',
      'icon': '👓',
      'widget': const RememberObjectsGame(),
    },
    {
      'id': 'memory_match',
      'title': 'Memory Match',
      'category': 'memory',
      'desc': 'Flip cards to discover matching pairs of familiar items.',
      'icon': '🍎',
      'widget': const MemoryMatchGame(),
    },
    {
      'id': 'routine_order',
      'title': 'Daily Routine Order',
      'category': 'routine',
      'desc': 'Arrange morning activities in their natural daily order.',
      'icon': '🌅',
      'widget': const RoutineOrderGame(),
    },
    {
      'id': 'find_different',
      'title': 'Find the Different Object',
      'category': 'attention',
      'desc': 'Spot the single object that stands out from the group.',
      'icon': '🔍',
      'widget': const FindDifferentGame(),
    },
    {
      'id': 'twin_shapes',
      'title': 'Twin Shapes & Color Match',
      'category': 'attention',
      'desc': 'Match objects with identical shapes and gentle colors.',
      'icon': '🔴',
      'widget': const TwinShapesGame(),
    },
    {
      'id': 'pattern_completion',
      'title': 'Pattern Completion',
      'category': 'pattern',
      'desc': 'Predict which shape naturally comes next in the visual sequence.',
      'icon': '🧩',
      'widget': const PatternCompletionGame(),
    },
    {
      'id': 'object_categorization',
      'title': 'Object Categorization',
      'category': 'pattern',
      'desc': 'Sort items into helpful groups: Food, Clothes, Medicine, Home.',
      'icon': '📦',
      'widget': const ObjectCategorizationGame(),
    },
    {
      'id': 'story_recall',
      'title': 'Story Recall',
      'category': 'language',
      'desc': 'Listen to a short pleasant story and answer simple questions.',
      'icon': '📖',
      'widget': const StoryRecallGame(),
    },
    {
      'id': 'emotion_recognition',
      'title': 'Emotion Recognition',
      'category': 'emotion',
      'desc': 'Identify feelings from warm, expressive facial expressions.',
      'icon': '😊',
      'widget': const EmotionRecognitionGame(),
    },
    {
      'id': 'face_name_memory',
      'title': 'Face & Name Memory',
      'category': 'memory',
      'desc': 'Recall familiar faces and family member names.',
      'icon': '👵',
      'widget': const FaceNameMemoryGame(),
    },
    {
      'id': 'location_memory',
      'title': 'Location Memory',
      'category': 'memory',
      'desc': 'Remember where familiar objects were placed in the home.',
      'icon': '🏡',
      'widget': const LocationMemoryGame(),
    },
    {
      'id': 'sound_memory',
      'title': 'Sound Memory',
      'category': 'auditory',
      'desc': 'Listen and recall sequences of soothing everyday sounds.',
      'icon': '🔔',
      'widget': const SoundMemoryGame(),
    },
    {
      'id': 'word_recall',
      'title': 'Word Recall',
      'category': 'language',
      'desc': 'Remember and select comforting words shown earlier.',
      'icon': '📝',
      'widget': const WordRecallGame(),
    },
    {
      'id': 'object_recognition',
      'title': 'Object Recognition',
      'category': 'language',
      'desc': 'Recognize and name household objects with multilingual audio.',
      'icon': '🕰️',
      'widget': const ObjectRecognitionGame(),
    },
    {
      'id': 'sequence_recall',
      'title': 'Simple Sequence Recall',
      'category': 'memory',
      'desc': 'Recall the gentle sequence of 3 familiar items.',
      'icon': '🔢',
      'widget': const SequenceRecallGame(),
    },
    {
      'id': 'missing_object',
      'title': 'Which One is Missing?',
      'category': 'memory',
      'desc': 'A group of objects is shown. Spot which one was removed.',
      'icon': '❓',
      'widget': const MissingObjectGame(),
    },
    {
      'id': 'match_pairs',
      'title': 'Match Related Pairs',
      'category': 'pattern',
      'desc': 'Connect related household pairs: Cup & Saucer, Lock & Key.',
      'icon': '☕',
      'widget': const MatchPairsGame(),
    },
    {
      'id': 'picture_word_match',
      'title': 'Picture & Word Match',
      'category': 'language',
      'desc': 'Match the picture of an apple, book, or chair with its name.',
      'icon': '🖼️',
      'widget': const PictureWordMatchGame(),
    },
  ];

  String _getGameTitle(String id, String fallback) {
    for (final k in ['game_${id}_title', 'game_${id.replaceAll('_memory', '')}_title', 'game_${id.replaceAll('_match', '')}_title']) {
      final val = context.tr(k);
      if (val != k) return val;
    }
    return fallback;
  }

  String _getGameDesc(String id, String fallback) {
    for (final k in ['game_${id}_desc', 'game_${id.replaceAll('_memory', '')}_desc', 'game_${id.replaceAll('_match', '')}_desc']) {
      final val = context.tr(k);
      if (val != k) return val;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = _selectedCategory == 'all'
        ? _allGames
        : _allGames.where((g) => g['category'] == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('cognitive_training_games'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                '18 ${context.tr('cognitive_training_games')}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),

        // Domain Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('${context.tr('view_all')} (18)', 'all'),
              _buildFilterChip('🧠 ${context.tr('cat_memory')}', 'memory'),
              _buildFilterChip('🎯 ${context.tr('cat_attention')}', 'attention'),
              _buildFilterChip('🧩 ${context.tr('cat_pattern')}', 'pattern'),
              _buildFilterChip('🌅 ${context.tr('cat_routine')}', 'routine'),
              _buildFilterChip('🔔 ${context.tr('cat_auditory')}', 'auditory'),
              _buildFilterChip('❤️ ${context.tr('cat_emotion')}', 'emotion'),
            ],
          ),
        ),

        // Games Grid
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: filteredGames.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final game = filteredGames[index];
              final title = _getGameTitle(game['id'] as String, game['title'] as String);
              final desc = _getGameDesc(game['id'] as String, game['desc'] as String);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Text(game['icon'], style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            desc,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => game['widget']));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('${context.tr('play_a_game')} →', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2563EB),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
