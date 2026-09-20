import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../database/database_helper.dart';
import '../auth/login_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  String? _selectedPatientId;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();

  List<Map<String, dynamic>> _assignedPatients = [];
  bool _isLoadingPatients = true;
  Map<String, dynamic>? _patientAssessment;
  bool _isLoadingAssessment = false;

  final List<String> _caregiverNotes = [
    "Steady focus and cheerful participation observed today.",
    "Enjoyed the morning routine and memory activity.",
  ];

  final List<String> _assignedTasks = [
    "Afternoon walk in the garden (15 mins)",
    "Drink warm water after memory activity",
    "Complete 1 Memory Match game before tea",
  ];

  @override
  void initState() {
    super.initState();
    _loadAssignedPatients();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignedPatients() async {
    setState(() => _isLoadingPatients = true);
    final token = AuthService.instance.token;
    final backendUrl = AuthService.instance.backendBaseUrl;

    try {
      if (token != null) {
        final res = await http.get(
          Uri.parse('$backendUrl/patients'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final List list = jsonDecode(res.body);
          if (list.isNotEmpty) {
            setState(() {
              _assignedPatients = list.map((p) {
                return {
                  'id': p['id'].toString(),
                  'name': p['name'] ?? 'Patient',
                  'age': p['age'] ?? 68,
                  'progress': (p['progress_pct'] ?? 40.0).toDouble().toInt(),
                  'gamesCount': p['games_completed'] ?? 1,
                  'mood': 'Calm',
                  'moodEmoji': '🙂',
                  'avatar': '👵',
                  'activeTasks': 3,
                  'initial_assessment_completed': p['initial_assessment_completed'] ?? false,
                };
              }).toList();
              _isLoadingPatients = false;
            });
            return;
          }
        }
      }
    } catch (_) {
      debugPrint('[CaregiverDashboard] Backend fetch failed; falling back to local DB/demo.');
    }

    // Fallback: If caregiver is default demo caregiver Ananya, provide Ifra & Taiba
    final cName = AuthService.instance.caregiverName ?? '';
    if (cName.contains('Ananya') || AuthService.instance.caregiverId == 'caregiver_01') {
      setState(() {
        _assignedPatients = [
          {
            'id': 'ifra_01',
            'name': 'Ifra',
            'age': 70,
            'progress': 48,
            'gamesCount': 2,
            'mood': 'Calm',
            'moodEmoji': '🙂',
            'avatar': '👵',
            'activeTasks': 3,
            'initial_assessment_completed': true,
          },
          {
            'id': 'taiba_02',
            'name': 'Taiba',
            'age': 72,
            'progress': 35,
            'gamesCount': 1,
            'mood': 'Peaceful',
            'moodEmoji': '😊',
            'avatar': '👵',
            'activeTasks': 2,
            'initial_assessment_completed': true,
          },
        ];
        _isLoadingPatients = false;
      });
    } else {
      // Newly registered caregiver without server response
      setState(() {
        _assignedPatients = [];
        _isLoadingPatients = false;
      });
    }
  }

  Future<void> _selectPatient(String patientId) async {
    setState(() {
      _selectedPatientId = patientId;
      _isLoadingAssessment = true;
      _patientAssessment = null;
    });

    // 1. Try local SQLite / Memory
    final localData = await DatabaseHelper.instance.getInitialAssessment(patientId);
    if (localData != null) {
      if (mounted) {
        setState(() {
          _patientAssessment = localData;
          _isLoadingAssessment = false;
        });
      }
      return;
    }

    // 2. Try backend
    try {
      final backendUrl = AuthService.instance.backendBaseUrl;
      final token = AuthService.instance.token;
      final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};
      final res = await http.get(
        Uri.parse('$backendUrl/patients/$patientId/initial-assessment'),
        headers: headers,
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _patientAssessment = data;
            _isLoadingAssessment = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingAssessment = false);
    }
  }

  void _addNote() {
    if (_noteController.text.trim().isNotEmpty) {
      setState(() {
        _caregiverNotes.insert(0, _noteController.text.trim());
        _noteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caregiver observation note saved successfully!')),
      );
    }
  }

  void _addTask() {
    if (_taskController.text.trim().isNotEmpty) {
      setState(() {
        _assignedTasks.add(_taskController.text.trim());
        _taskController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New activity task assigned to patient!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final caregiverName = AuthService.instance.caregiverName ?? 'Caregiver';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NEURAL NEXUS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Color(0xFF0F766E),
              ),
            ),
            const Text(
              'Caregiver Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F766E)),
            tooltip: 'Refresh Patients',
            onPressed: _loadAssignedPatients,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Logout',
            onPressed: () {
              AuthService.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _selectedPatientId == null
            ? _buildPatientsListView(caregiverName)
            : _buildPatientDetailsView(_selectedPatientId!),
      ),
    );
  }

  Widget _buildPatientsListView(String caregiverName) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Welcome Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👨‍⚕️', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $caregiverName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Caregiver Portal • ${_assignedPatients.length} Assigned Patients',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCCFBF1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Assigned Patients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        if (_isLoadingPatients)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
            ),
          )
        else if (_assignedPatients.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: const [
                Icon(Icons.person_off_outlined, size: 48, color: Color(0xFF94A3B8)),
                SizedBox(height: 12),
                Text(
                  'No Patients Assigned Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Newly registered patients assigned to your account will automatically appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ..._assignedPatients.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: _buildPatientCard(
                id: p['id'],
                name: p['name'],
                age: p['age'],
                progress: p['progress'],
                gamesCount: p['gamesCount'],
                mood: p['mood'],
                moodEmoji: p['moodEmoji'],
                avatar: p['avatar'],
                activeTasks: p['activeTasks'],
                assessmentCompleted: p['initial_assessment_completed'] ?? false,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPatientCard({
    required String id,
    required String name,
    required int age,
    required int progress,
    required int gamesCount,
    required String mood,
    required String moodEmoji,
    required String avatar,
    required int activeTasks,
    required bool assessmentCompleted,
  }) {
    return InkWell(
      onTap: () => _selectPatient(id),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(avatar, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name ($age yrs)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Mood: $mood $moodEmoji',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (assessmentCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Assessed ✓',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF7E22CE),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$progress% Done',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$gamesCount daily games completed',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                Row(
                  children: const [
                    Text(
                      'View Profile',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0F766E)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientDetailsView(String patientId) {
    final patient = _assignedPatients.firstWhere(
      (p) => p['id'] == patientId,
      orElse: () => {
        'id': patientId,
        'name': 'Patient',
        'age': 68,
        'progress': 40,
        'gamesCount': 1,
        'mood': 'Calm',
        'moodEmoji': '🙂',
        'avatar': '👵',
      },
    );
    final patientName = patient['name'];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Back Button
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _selectedPatientId = null),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF0F172A)),
                    SizedBox(width: 6),
                    Text(
                      'All Patients',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Patient Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Text(patient['avatar'], style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$patientName (${patient['age']} yrs)',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Active Dementia Cognitive Support Plan',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 10-Question Initial Assessment Section (Problem 7 Requirement)
        _buildInitialAssessmentCard(patientId, patientName),
        const SizedBox(height: 16),

        // Metrics Grid (Analytics & Trends)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Today’s Progress',
                '${patient['progress']}%',
                '${patient['gamesCount']} exercises done',
                const Color(0xFF2563EB),
                const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Mood State',
                '${patient['mood']} ${patient['moodEmoji']}',
                'Positive & steady today',
                const Color(0xFF10B981),
                const Color(0xFFF0FDF4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Caregiver Observation Notes
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Caregiver Notes & Observations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Add an observation note...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Note'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._caregiverNotes.map((note) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_alt_outlined, color: Color(0xFF0F766E), size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(note, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Assigned Tasks Section
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigned Tasks to $patientName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        hintText: 'Assign a new task to $patientName...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Assign Task'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._assignedTasks.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outlined, color: Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialAssessmentCard(String patientId, String patientName) {
    if (_isLoadingAssessment) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF7E22CE)),
        ),
      );
    }

    final assess = _patientAssessment;
    if (assess == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.assignment_late_outlined, color: Color(0xFF94A3B8), size: 22),
                SizedBox(width: 10),
                Text(
                  'Initial 10-Question Assessment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$patientName has not completed their 10-question initial assessment yet. Once submitted, answers will appear here.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      );
    }

    final responses = (assess['responses'] as List?) ?? [];
    final yesCount = assess['yes_count'] ?? responses.where((r) => r['answer'] == 'Yes').length;
    final noCount = assess['no_count'] ?? responses.where((r) => r['answer'] == 'No').length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E22CE).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF7E22CE), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Initial 10-Question Assessment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Completed ✓',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  'Yes: $yesCount',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16A34A), fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  'No: $noCount',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDC2626), fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Language: ${(assess['language'] ?? 'en').toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 24),

          // All 10 Individual Questions & Answers (Caregiver Visibility Requirement)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'View All ${responses.length} Question Responses',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF7E22CE)),
              ),
              children: responses.map<Widget>((r) {
                final qNum = r['question_id'] ?? 1;
                final charName = r['character_name'] ?? '';
                final location = r['location'] ?? '';
                final ans = r['answer'] ?? 'No';
                final isYes = ans == 'Yes';
                final qText = r['question_text'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Q$qNum: $charName ($location)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isYes ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ans,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isYes ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        qText,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
