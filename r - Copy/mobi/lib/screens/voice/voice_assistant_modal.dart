import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../services/voice_service.dart';
import '../../games/remember_objects_game.dart';
import '../reminders/reminder_screen.dart';

class VoiceAssistantModal extends StatefulWidget {
  final int pendingReminders;
  final double progress;

  const VoiceAssistantModal({
    super.key,
    required this.pendingReminders,
    required this.progress,
  });

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal> {
  String? _assistantResponse;
  bool _isSpeaking = false;

  void _triggerCommand(String cmd) {
    setState(() => _isSpeaking = true);
    final result = VoiceService.instance.processVoiceCommand(
      cmd,
      pendingReminders: widget.pendingReminders,
      progress: widget.progress,
    );

    setState(() {
      _assistantResponse = result['response'];
      _isSpeaking = false;
    });

    if (result['action'] == 'NAVIGATE_GAME') {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RememberObjectsGame()));
        }
      });
    } else if (result['action'] == 'NAVIGATE_REMINDERS') {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen()));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultResponse = context.tr('nia_greeting');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),

          // Animated Nia Avatar
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF10B981)]),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(_isSpeaking ? Icons.graphic_eq : Icons.mic_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 14),

          Text(
            'Nia — ${context.tr('voice_assistant')}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          // Nia Speech Output Bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _assistantResponse ?? defaultResponse,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            context.tr('nia_tap_to_speak'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),

          // Quick Commands Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildCommandChip('🎮 ${context.tr('play_a_game')}', 'Play memory game'),
              _buildCommandChip('💊 ${context.tr('reminders')}', 'Read my reminders'),
              _buildCommandChip('📊 ${context.tr('your_progress')}', 'Show progress'),
              _buildCommandChip('🌐 ${context.tr('select_language')}', 'Change language'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommandChip(String label, String command) {
    return ActionChip(
      onPressed: () => _triggerCommand(command),
      label: Text(label),
      backgroundColor: const Color(0xFFEFF6FF),
      labelStyle: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFBFDBFE)),
      ),
    );
  }
}
