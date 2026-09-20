import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/voice_service.dart';
import '../patient/patient_home_screen.dart';
import '../caregiver/caregiver_dashboard_screen.dart';
import '../assessment/initial_10_question_assessment_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Login Mode: 'patient' or 'caregiver'
  String _activeTab = 'patient';

  // Patient Login state (Pin or Username)
  bool _useUsernameForPatient = false;
  final TextEditingController _patientUsernameController = TextEditingController();
  final TextEditingController _patientPasswordController = TextEditingController();

  String _selectedPatient = 'Ifra';
  String _pin = '';
  String? _errorMessage;

  // Caregiver Login state
  final TextEditingController _emailController =
      TextEditingController(text: 'caregiver@neuralnexus.demo');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Caregiver@123');
  bool _isLoading = false;

  @override
  void dispose() {
    _patientUsernameController.dispose();
    _patientPasswordController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Patient PIN Handlers ---
  void _onKeyPress(String val) {
    VoiceService.instance.speakTap('Key $val');
    if (_pin.length < 4) {
      setState(() {
        _pin += val;
        _errorMessage = null;
      });
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    VoiceService.instance.speakTap('Delete');
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    if (_pin == '1234') {
      final pId = _selectedPatient == 'Ifra' ? 'ifra_01' : 'taiba_02';
      AuthService.instance.setPatient(
        id: pId,
        name: _selectedPatient,
        language: AuthService.instance.currentLanguage,
        assessmentCompleted: true, // Demo accounts have initial assessment completed
      );
      _routePatient(hasCompletedAssessment: true);
    } else {
      setState(() {
        _errorMessage = context.tr('login_pin_error');
        _pin = '';
      });
    }
  }

  void _quickDemoLogin(String name) {
    VoiceService.instance.speakTap(name);
    setState(() {
      _selectedPatient = name;
      _pin = '1234';
    });
    _verifyPin();
  }

  Future<void> _loginPatientWithPassword() async {
    final username = _patientUsernameController.text.trim();
    final password = _patientPasswordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter username and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.instance.loginWithCredentials(username, password);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final isCompleted = AuthService.instance.initialAssessmentCompleted;
      _routePatient(hasCompletedAssessment: isCompleted);
    } else {
      setState(() => _errorMessage = res['error'] ?? 'Login failed.');
    }
  }

  void _routePatient({required bool hasCompletedAssessment}) {
    if (!hasCompletedAssessment) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const Initial10QuestionAssessmentScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
      );
    }
  }

  // --- Caregiver Login Handlers ---
  Future<void> _loginCaregiver() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email/username and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.instance.loginWithCredentials(email, password);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CaregiverDashboardScreen()),
        );
      }
    } else {
      setState(() => _errorMessage = res['error'] ?? 'Invalid credentials.');
    }
  }

  // --- Registration Dialog Modal (New User Assessment Requirement) ---
  void _openRegisterDialog() {
    VoiceService.instance.speakTap('Open account registration');
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '70');
    final phoneCtrl = TextEditingController();
    String regRole = _activeTab == 'caregiver' ? 'CAREGIVER' : 'PATIENT';
    String regLang = AuthService.instance.currentLanguage;
    String? regError;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Create New Account',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Join NEURAL NEXUS Brain Training',
                            style: TextStyle(fontSize: 13, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Role Selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Patient Account')),
                          selected: regRole == 'PATIENT',
                          selectedColor: const Color(0xFFCCFBF1),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: regRole == 'PATIENT' ? const Color(0xFF0F766E) : const Color(0xFF475569),
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => regRole = 'PATIENT');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Caregiver Account')),
                          selected: regRole == 'CAREGIVER',
                          selectedColor: const Color(0xFFCCFBF1),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: regRole == 'CAREGIVER' ? const Color(0xFF0F766E) : const Color(0xFF475569),
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => regRole = 'CAREGIVER');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: regRole == 'PATIENT' ? 'Patient Full Name' : 'Caregiver Full Name',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Username
                  TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Username or Email',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Additional fields for Patient
                  if (regRole == 'PATIENT') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age (Years)',
                              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: regLang,
                            decoration: InputDecoration(
                              labelText: 'Language',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('English')),
                              DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                              DropdownMenuItem(value: 'as', child: Text('অসমীয়া')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => regLang = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Phone / Contact
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (regError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        regError!,
                        style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final u = usernameCtrl.text.trim();
                              final p = passwordCtrl.text;
                              final n = nameCtrl.text.trim();
                              if (u.isEmpty || p.isEmpty || n.isEmpty) {
                                setModalState(() => regError = 'Please fill in name, username, and password.');
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                                regError = null;
                              });

                              final res = await AuthService.instance.registerUser(
                                username: u,
                                password: p,
                                fullName: n,
                                role: regRole,
                                age: int.tryParse(ageCtrl.text) ?? 68,
                                primaryLanguage: regLang,
                                phone: phoneCtrl.text.trim(),
                              );

                              setModalState(() => isSubmitting = false);

                              if (res['success'] == true) {
                                Navigator.of(ctx).pop();
                                if (regRole == 'PATIENT') {
                                  // Problem 7: Automatic routing to Initial 10-Question Assessment
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const Initial10QuestionAssessmentScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const CaregiverDashboardScreen(),
                                    ),
                                  );
                                }
                              } else {
                                setModalState(() => regError = res['error'] ?? 'Registration failed.');
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              regRole == 'PATIENT' ? 'Register & Start Assessment' : 'Register Caregiver',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final current = AuthService.instance.currentLanguage;
    final langs = [
      {'code': 'en', 'label': 'English'},
      {'code': 'hi', 'label': 'हिंदी'},
      {'code': 'as', 'label': 'অসমীয়া'},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 16, color: Color(0xFF0D9488)),
          const SizedBox(width: 6),
          ...langs.map((l) {
            final isSelected = current == l['code'];
            return GestureDetector(
              onTap: () {
                VoiceService.instance.speakTap(l['label']!);
                AuthService.instance.switchLanguage(l['code']!);
                setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  l['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Language Switcher
              Align(
                alignment: Alignment.centerRight,
                child: _buildLanguageSelector(),
              ),
              const SizedBox(height: 12),

              // Logo & Title
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/neural_nexus_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.favorite, size: 40, color: Color(0xFF0D9488)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'NEURAL NEXUS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('app_subtitle'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 20),

              // Mode Tabs: Patient vs Caregiver
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: context.tr('login_tab_patient'),
                        icon: Icons.person,
                        isActive: _activeTab == 'patient',
                        onTap: () {
                          VoiceService.instance.speakTap('Patient Login');
                          setState(() {
                            _activeTab = 'patient';
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: context.tr('login_tab_caregiver'),
                        icon: Icons.favorite,
                        isActive: _activeTab == 'caregiver',
                        onTap: () {
                          VoiceService.instance.speakTap('Caregiver Login');
                          setState(() {
                            _activeTab = 'caregiver';
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Content based on selected tab
              if (_activeTab == 'patient') _buildPatientLoginCard() else _buildCaregiverLoginCard(),

              const SizedBox(height: 16),

              // Register Button Modal
              TextButton.icon(
                icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0F766E)),
                label: Text(
                  _activeTab == 'patient'
                      ? '✨ New Patient? Create Account & Start Assessment'
                      : '✨ New Caregiver? Register Here',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F766E),
                  ),
                ),
                onPressed: _openRegisterDialog,
              ),

              const SizedBox(height: 8),

              // Clinical Disclaimer
              Text(
                context.tr('login_disclaimer'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? const Color(0xFF0D9488) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PATIENT LOGIN CARD ---
  Widget _buildPatientLoginCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('login_select_profile'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _useUsernameForPatient = !_useUsernameForPatient);
                },
                child: Text(
                  _useUsernameForPatient ? 'Use PIN Mode' : 'Use Password',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (!_useUsernameForPatient) ...[
            // Quick profile selectors
            Row(
              children: [
                Expanded(
                  child: _buildPatientProfileChip(
                    name: 'Ifra',
                    age: '68',
                    isSelected: _selectedPatient == 'Ifra',
                    onTap: () => setState(() => _selectedPatient = 'Ifra'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPatientProfileChip(
                    name: 'Taiba',
                    age: '72',
                    isSelected: _selectedPatient == 'Taiba',
                    onTap: () => setState(() => _selectedPatient = 'Taiba'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // PIN Display Dots
            Center(
              child: Column(
                children: [
                  Text(
                    '${context.tr('login_enter_pin')} ($_selectedPatient)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                          border: Border.all(
                            color: isFilled ? const Color(0xFF0D9488) : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Keypad
            Column(
              children: [
                _buildKeypadRow(['1', '2', '3']),
                const SizedBox(height: 10),
                _buildKeypadRow(['4', '5', '6']),
                const SizedBox(height: 10),
                _buildKeypadRow(['7', '8', '9']),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildKeypadButton('C', isAction: true, onTap: () => setState(() => _pin = '')),
                    _buildKeypadButton('0', onTap: () => _onKeyPress('0')),
                    _buildKeypadButton('⌫', isAction: true, onTap: _onBackspace),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Demo 1-Tap Login
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _quickDemoLogin(_selectedPatient),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('${context.tr('login_quick_demo')} ($_selectedPatient)'),
              ),
            ),
          ] else ...[
            // Username + Password Form for Patients
            TextField(
              controller: _patientUsernameController,
              decoration: InputDecoration(
                labelText: 'Username or Email',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _patientPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _loginPatientWithPassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login as Patient', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientProfileChip({
    required String name,
    required String age,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCCFBF1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
              child: Text(
                name[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '$age years',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CAREGIVER LOGIN CARD ---
  Widget _buildCaregiverLoginCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('login_caregiver_portal'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('login_caregiver_sub'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Email
          Text(
            context.tr('login_email'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
              hintText: 'caregiver@neuralnexus.demo or username',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Password
          Text(
            context.tr('login_password'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              hintText: '••••••••',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loginCaregiver,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(context.tr('login_signin_btn'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Demo Caregiver Login
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                _emailController.text = 'caregiver@neuralnexus.demo';
                _passwordController.text = 'Caregiver@123';
                _loginCaregiver();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
                side: const BorderSide(color: Color(0xFF0D9488)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                context.tr('login_quick_caregiver'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((k) => _buildKeypadButton(k, onTap: () => _onKeyPress(k))).toList(),
    );
  }

  Widget _buildKeypadButton(String label, {bool isAction = false, required VoidCallback onTap}) {
    return Material(
      color: isAction ? const Color(0xFFE2E8F0) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: isAction ? 0 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 78,
          height: 56,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isAction ? const Color(0xFF475569) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
