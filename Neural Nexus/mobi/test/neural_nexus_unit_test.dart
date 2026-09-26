import 'package:flutter_test/flutter_test.dart';
import 'package:neural_nexus/models/assessment_model.dart';
import 'package:neural_nexus/models/rewards_model.dart';
import 'package:neural_nexus/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Neural Nexus Comprehensive Unit Tests', () {
    test('10 Regional Stories and Questions are fully configured', () {
      expect(kInitial10Questions.length, 10);

      // Verify Question 1: Anima, Jorhat
      final q1 = kInitial10Questions[0];
      expect(q1.characterName, 'Anima');
      expect(q1.locationBadge, 'Jorhat, Assam');
      expect(q1.storyEn.contains('Bihu'), isTrue);
      expect(q1.storyHi.contains('बिहू'), isTrue);
      expect(q1.storyAs.contains('বিহু'), isTrue);

      // Verify Question 2: Ato, Kohima
      final q2 = kInitial10Questions[1];
      expect(q2.characterName, 'Ato');
      expect(q2.locationBadge, 'Kohima, Nagaland');

      // Verify Question 3: Meban, Shillong
      final q3 = kInitial10Questions[2];
      expect(q3.characterName, 'Meban');
      expect(q3.locationBadge, 'Shillong, Meghalaya');

      // Verify Question 4: Thangjam, Imphal
      final q4 = kInitial10Questions[3];
      expect(q4.characterName, 'Thangjam');
      expect(q4.locationBadge, 'Imphal, Manipur');

      // Verify Question 5: Lalhmingi, Aizawl
      final q5 = kInitial10Questions[4];
      expect(q5.characterName, 'Lalhmingi');
      expect(q5.locationBadge, 'Aizawl, Mizoram');

      // Verify Question 6: Bimal, Agartala
      final q6 = kInitial10Questions[5];
      expect(q6.characterName, 'Bimal');
      expect(q6.locationBadge, 'Agartala, Tripura');

      // Verify Question 7: Tashi, Itanagar
      final q7 = kInitial10Questions[6];
      expect(q7.characterName, 'Tashi');
      expect(q7.locationBadge, 'Itanagar, Arunachal Pradesh');

      // Verify Question 8: Dorjee, Gangtok
      final q8 = kInitial10Questions[7];
      expect(q8.characterName, 'Dorjee');
      expect(q8.locationBadge, 'Gangtok, Sikkim');

      // Verify Question 9: Jonali, Dibrugarh
      final q9 = kInitial10Questions[8];
      expect(q9.characterName, 'Jonali');
      expect(q9.locationBadge, 'Dibrugarh, Assam');

      // Verify Question 10: Neikha, Dimapur
      final q10 = kInitial10Questions[9];
      expect(q10.characterName, 'Neikha');
      expect(q10.locationBadge, 'Dimapur, Nagaland');
    });

    test('InitialAssessmentResponseItem correctly formats to JSON and Map', () {
      final item = InitialAssessmentResponseItem(
        questionId: 1,
        characterName: 'Anima',
        location: 'Jorhat, Assam',
        questionText: 'Did you forget recent conversations?',
        storySummary: 'Anima preparing for Bihu',
        answer: 'Yes',
        language: 'en',
      );

      final json = item.toJson();
      expect(json['question_id'], 1);
      expect(json['character_name'], 'Anima');
      expect(json['answer'], 'Yes');
      expect(json['language'], 'en');

      final map = item.toMap('assess_123');
      expect(map['id'], 'assess_123_q1');
      expect(map['assessment_id'], 'assess_123');
    });

    test('RewardsState addXp and Level Progression', () {
      final rewards = RewardsState(xp: 0, gamificationLevel: 1, streakDays: 1);
      expect(rewards.xp, 0);
      expect(rewards.gamificationLevel, 1);

      // Add 50 XP (Initial assessment bonus)
      rewards.addXp(50);
      expect(rewards.xp, 50);
      expect(rewards.gamificationLevel, 1);

      // Add 60 XP (crosses 100 XP -> Level 2)
      rewards.addXp(60);
      expect(rewards.xp, 110);
      expect(rewards.gamificationLevel, 2);
    });

    test('RewardsState Daily Reward Unlock', () {
      final rewards = RewardsState(xp: 100, dailyRewardUnlockedToday: false);
      rewards.unlockDailyReward();
      expect(rewards.dailyRewardUnlockedToday, isTrue);
      expect(rewards.xp, 125);
    });

    test('DatabaseHelper duplicate reward prevention', () async {
      final db = DatabaseHelper.instance;
      final patientId = 'test_patient_xp';

      await db.addRewardXp(patientId, 25, eventKey: 'game_session_1');
      final xpAfterFirst = db.rewardsState.xp;

      // Adding with same eventKey should NOT duplicate XP
      await db.addRewardXp(patientId, 25, eventKey: 'game_session_1');
      expect(db.rewardsState.xp, xpAfterFirst);
    });
  });
}
