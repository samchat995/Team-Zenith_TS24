import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../models/memory_item_model.dart';

class MyMemoryScreen extends StatefulWidget {
  const MyMemoryScreen({super.key});

  @override
  State<MyMemoryScreen> createState() => _MyMemoryScreenState();
}

class _MyMemoryScreenState extends State<MyMemoryScreen> {
  String _selectedFilter = 'all';

  final List<MemoryItemModel> _items = [
    MemoryItemModel(
      id: 'm1',
      patientId: 'p1',
      category: 'family',
      title: 'Meena',
      relationship: 'Granddaughter',
      details: 'Meena loves reading storybooks with me and brought lovely yellow marigolds from the garden.',
    ),
    MemoryItemModel(
      id: 'm2',
      patientId: 'p1',
      category: 'favorite',
      title: 'Assam Cardamom Tea',
      details: 'Enjoying 1 cup of warm tea with freshly crushed cardamom on the veranda at 4:30 PM.',
    ),
    MemoryItemModel(
      id: 'm3',
      patientId: 'p1',
      category: 'place',
      title: 'Front Porch Garden',
      details: 'Sitting on the wooden cane chair watching afternoon sparrows bathe near the flowerpot.',
    ),
    MemoryItemModel(
      id: 'm4',
      patientId: 'p1',
      category: 'routine',
      title: 'Evening Radio Music',
      details: 'Listening to gentle acoustic melodies and devotional songs before evening dinner.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'all'
        ? _items
        : _items.where((item) => item.category == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        title: Text(context.tr('memory_title'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilter('${context.tr('view_all')} (${_items.length})', 'all'),
                _buildFilter('👨‍👩‍👧 ${context.tr('memory_family')}', 'family'),
                _buildFilter('🍵 ${context.tr('memory_food')}', 'favorite'),
                _buildFilter('🏡 ${context.tr('memory_places')}', 'place'),
                _buildFilter('🌅 ${context.tr('cat_routine')}', 'routine'),
              ],
            ),
          ),

          // Memories List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF7E22CE)),
                            ),
                          ),
                          if (item.relationship != null)
                            Text(
                              item.relationship!,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B21A8)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.details,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(String label, String category) {
    final isSelected = _selectedFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedFilter = category),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF7C3AED),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
