import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../models/reminder_model.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  String _selectedCategory = 'all';

  late List<ReminderModel> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = [
      ReminderModel(
        id: 'r1',
        patientId: 'p1',
        title: 'Afternoon Blood Pressure Medicine',
        reminderType: 'medicine',
        timeOfDay: '02:00 PM',
        notes: 'Take 1 tablet with lukewarm water after lunch.',
        completed: false,
      ),
      ReminderModel(
        id: 'r2',
        patientId: 'p1',
        title: 'Afternoon Hydration — Warm Water',
        reminderType: 'hydration',
        timeOfDay: '04:00 PM',
        notes: 'Drink 1 full glass of fresh warm water.',
        completed: false,
      ),
      ReminderModel(
        id: 'r3',
        patientId: 'p1',
        title: 'Morning Walk in the Garden',
        reminderType: 'daily_activity',
        timeOfDay: '08:00 AM',
        notes: '15-minute gentle stroll.',
        completed: true,
      ),
      ReminderModel(
        id: 'r4',
        patientId: 'p1',
        title: 'Dr. Ritasri Follow-Up Check-In',
        reminderType: 'appointment',
        timeOfDay: '11:30 AM',
        notes: 'Monthly cognitive health review.',
        completed: false,
      ),
    ];
  }

  void _toggleDone(String id) {
    setState(() {
      final idx = _reminders.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final current = _reminders[idx];
        _reminders[idx] = current.copyWith(completed: !current.completed);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder updated! Keep up the healthy routine.')),
    );
  }

  void _remindLater(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Snoozed "$title". We will gently remind you in 30 minutes.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'all'
        ? _reminders
        : _reminders.where((r) => r.reminderType == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(context.tr('reminders_title'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('${context.tr('view_all')} (${_reminders.length})', 'all'),
                _buildFilterChip('💊 ${context.tr('qa_medicine')}', 'medicine'),
                _buildFilterChip('💧 ${context.tr('qa_hydration')}', 'hydration'),
                _buildFilterChip('🌞 ${context.tr('qa_walk')}', 'daily_activity'),
                _buildFilterChip('📅 ${context.tr('qa_appointments')}', 'appointment'),
              ],
            ),
          ),

          // Reminders List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final r = filtered[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: r.completed ? const Color(0xFFF1F5F9) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: r.completed ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                    boxShadow: r.completed
                        ? []
                        : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(_getIcon(r.reminderType), style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 10),
                              Text(
                                r.timeOfDay,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                          if (r.completed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                              child: const Text('✓ COMPLETED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        r.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: r.completed ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                          decoration: r.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (r.notes != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          r.notes!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Large Elderly Action Buttons (Done / Remind Later)
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: ElevatedButton.icon(
                              onPressed: () => _toggleDone(r.id),
                              icon: Icon(r.completed ? Icons.undo_rounded : Icons.check_circle_rounded, size: 18),
                              label: Text(r.completed ? 'Mark Incomplete' : 'DONE', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: r.completed ? const Color(0xFFE2E8F0) : const Color(0xFF10B981),
                                foregroundColor: r.completed ? const Color(0xFF475569) : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (!r.completed)
                            Expanded(
                              flex: 5,
                              child: OutlinedButton.icon(
                                onPressed: () => _remindLater(r.title),
                                icon: const Icon(Icons.access_time_rounded, size: 16),
                                label: const Text('Remind Later', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF475569),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                        ],
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

  String _getIcon(String type) {
    switch (type) {
      case 'medicine':
        return '💊';
      case 'hydration':
        return '💧';
      case 'daily_activity':
        return '🌞';
      case 'appointment':
        return '🩺';
      default:
        return '🔔';
    }
  }

  Widget _buildFilterChip(String label, String code) {
    final isSelected = _selectedCategory == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = code),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2563EB),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
