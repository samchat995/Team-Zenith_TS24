import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../services/auth_service.dart';
import '../memory/my_memory_screen.dart';

class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientName = AuthService.instance.patientName;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('caregiver_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('caregiver_subtitle'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Caregiver Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
                  child: const Center(child: Text('👩👧', style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ananya Sharma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(context.tr('caregiver_primary'), style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${context.tr('caregiver_assigned')}: Ifra & Taiba', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recent Caregiver Note
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 8),
                    Text('${context.tr('caregiver_message_from')} Ananya', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"Good evening $patientName! Don\'t forget to drink a warm glass of water after your memory activity. Have a wonderful rest!"',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF166534), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // "My Memory" Personalized Feature Card
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyMemoryScreen()));
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC4B5FD)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: const Center(child: Text('📸', style: TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('memory_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF5B21B6))),
                        const SizedBox(height: 2),
                        Text(context.tr('memory_subtitle'), style: const TextStyle(fontSize: 12, color: Color(0xFF6D28D9))),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF5B21B6), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
