import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('todays_progress'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('progress_effort'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Overall Today Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0284C7)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('score_label').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF93C5FD))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('48%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFFDE047), size: 48),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '2 ${context.tr('games_completed')}.\n${context.tr('keep_learning')}',
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            context.tr('cognitive_training_games'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          _buildDomainRating(context.tr('cat_memory'), '⭐⭐⭐⭐', context.tr('cat_memory_sub'), const Color(0xFFFCE7F3)),
          const SizedBox(height: 10),
          _buildDomainRating(context.tr('cat_attention'), '⭐⭐⭐⭐', context.tr('cat_attention_sub'), const Color(0xFFE0F2FE)),
          const SizedBox(height: 10),
          _buildDomainRating(context.tr('cat_pattern'), '⭐⭐⭐', context.tr('cat_pattern_sub'), const Color(0xFFEDE9FE)),
          const SizedBox(height: 10),
          _buildDomainRating(context.tr('cat_routine'), '⭐⭐⭐⭐⭐', context.tr('cat_routine_sub'), const Color(0xFFDCFCE7)),
          const SizedBox(height: 24),

          // Encouraging Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Text('🌻', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('bubble_quote'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainRating(String title, String stars, String note, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
            child: const Center(child: Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    Text(stars, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(note, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
