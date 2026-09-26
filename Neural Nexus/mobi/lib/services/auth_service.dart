import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  String? _token;
  String? _userId;
  String? _username;
  String? _patientId;
  String _patientName = 'Ifra';
  String _role = 'Patient';
  String _language = 'en';
  bool _initialAssessmentCompleted = false;

  String? _caregiverId;
  String? _caregiverName;
  String? _caregiverEmail;

  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  String? get patientId => _patientId;
  String get patientName => _patientName;
  String get role => _role;
  String get language => _language;
  String get currentLanguage => _language;
  bool get initialAssessmentCompleted => _initialAssessmentCompleted;
  bool get isLoggedIn => _patientId != null || _caregiverId != null || _token != null;
  bool get isCaregiver => _role.toUpperCase() == 'CAREGIVER';
  String? get caregiverId => _caregiverId;
  String? get caregiverName => _caregiverName;
  String? get caregiverEmail => _caregiverEmail;

  String get backendBaseUrl => kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';

  /// Load persisted credentials & language on startup
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('selected_language');
      if (savedLang != null && ['en', 'hi', 'as'].contains(savedLang)) {
        _language = savedLang;
      }
      _patientId = prefs.getString('auth_patient_id');
      _patientName = prefs.getString('auth_patient_name') ?? 'Ifra';
      _role = prefs.getString('auth_role') ?? 'Patient';
      _token = prefs.getString('auth_token');
      _userId = prefs.getString('auth_user_id');
      _username = prefs.getString('auth_username');
      _caregiverId = prefs.getString('auth_caregiver_id');
      _caregiverName = prefs.getString('auth_caregiver_name');
      _caregiverEmail = prefs.getString('auth_caregiver_email');

      if (_patientId != null) {
        _initialAssessmentCompleted = prefs.getBool('assess_completed_$_patientId') ?? false;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> initLanguage() async => init();

  void setPatient({
    required String id,
    required String name,
    String? language,
    bool assessmentCompleted = false,
  }) async {
    _patientId = id;
    _patientName = name;
    _role = 'Patient';
    if (language != null && ['en', 'hi', 'as'].contains(language)) {
      _language = language;
    }
    _initialAssessmentCompleted = assessmentCompleted;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_patient_id', id);
      await prefs.setString('auth_patient_name', name);
      await prefs.setString('auth_role', 'Patient');
      final savedStatus = prefs.getBool('assess_completed_$id');
      if (savedStatus != null) {
        _initialAssessmentCompleted = savedStatus;
      } else {
        await prefs.setBool('assess_completed_$id', assessmentCompleted);
      }
    } catch (_) {}
  }

  void setCaregiver({
    required String id,
    required String name,
    required String email,
    String? language,
  }) async {
    _caregiverId = id;
    _caregiverName = name;
    _caregiverEmail = email;
    _role = 'CAREGIVER';
    if (language != null && ['en', 'hi', 'as'].contains(language)) {
      _language = language;
    }
    _patientId = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_caregiver_id', id);
      await prefs.setString('auth_caregiver_name', name);
      await prefs.setString('auth_caregiver_email', email);
      await prefs.setString('auth_role', 'CAREGIVER');
    } catch (_) {}
  }

  Future<void> markInitialAssessmentCompleted({String? pId}) async {
    final targetId = pId ?? _patientId;
    if (targetId == null) return;
    _initialAssessmentCompleted = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('assess_completed_$targetId', true);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> loginWithCredentials(String usernameOrEmail, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$backendBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': usernameOrEmail, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['access_token'];
        _userId = data['user_id'];
        _role = data['role'] ?? 'Patient';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token ?? '');
        await prefs.setString('auth_user_id', _userId ?? '');
        await prefs.setString('auth_role', _role);

        if (_role.toUpperCase() == 'CAREGIVER') {
          _caregiverId = data['user_id'];
          _caregiverName = data['full_name'] ?? usernameOrEmail;
          _caregiverEmail = usernameOrEmail;
          _patientId = null;
          await prefs.setString('auth_caregiver_id', _caregiverId!);
          await prefs.setString('auth_caregiver_name', _caregiverName!);
        } else {
          _patientId = data['patient_id'] ?? data['user_id'];
          _patientName = data['full_name'] ?? usernameOrEmail;
          await prefs.setString('auth_patient_id', _patientId!);
          await prefs.setString('auth_patient_name', _patientName);

          // Check assessment status from prefs or backend
          final savedStatus = prefs.getBool('assess_completed_$_patientId');
          _initialAssessmentCompleted = savedStatus ?? false;
        }

        notifyListeners();
        return {'success': true, 'role': _role, 'data': data};
      } else {
        final error = jsonDecode(res.body);
        return {'success': false, 'error': error['detail'] ?? 'Login failed. Please check credentials.'};
      }
    } catch (e) {
      // Offline fallback for demo accounts
      if (usernameOrEmail == 'caregiver@neuralnexus.demo' || usernameOrEmail == 'Ananya' || usernameOrEmail == 'ananya') {
        setCaregiver(id: 'caregiver_01', name: 'Ananya Sharma', email: 'caregiver@neuralnexus.demo');
        return {'success': true, 'role': 'CAREGIVER'};
      } else if (usernameOrEmail.toLowerCase().contains('ifra')) {
        setPatient(id: 'ifra_01', name: 'Ifra', assessmentCompleted: true);
        return {'success': true, 'role': 'PATIENT'};
      } else if (usernameOrEmail.toLowerCase().contains('taiba')) {
        setPatient(id: 'taiba_02', name: 'Taiba', assessmentCompleted: true);
        return {'success': true, 'role': 'PATIENT'};
      }
      return {'success': false, 'error': 'Network connection failed and user not cached locally.'};
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
    required String fullName,
    required String role, // 'PATIENT' or 'CAREGIVER'
    int? age,
    String? gender,
    String? primaryLanguage,
    String? phone,
    String? assignedCaregiverId,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'username': username,
        'password': password,
        'full_name': fullName,
        'role': role.toUpperCase(),
        'phone': phone ?? '',
      };
      if (role.toUpperCase() == 'PATIENT') {
        payload['age'] = age ?? 68;
        payload['gender'] = gender ?? 'Other';
        payload['primary_language'] = primaryLanguage ?? _language;
        if (assignedCaregiverId != null && assignedCaregiverId.isNotEmpty) {
          payload['assigned_caregiver_id'] = assignedCaregiverId;
        }
      }

      final res = await http.post(
        Uri.parse('$backendBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['access_token'];
        _userId = data['user_id'];
        _role = data['role'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token ?? '');
        await prefs.setString('auth_user_id', _userId ?? '');
        await prefs.setString('auth_role', _role);

        if (_role.toUpperCase() == 'CAREGIVER') {
          _caregiverId = data['user_id'];
          _caregiverName = fullName;
          _caregiverEmail = username;
          _patientId = null;
          await prefs.setString('auth_caregiver_id', _caregiverId!);
          await prefs.setString('auth_caregiver_name', _caregiverName!);
        } else {
          _patientId = data['patient_id'] ?? data['user_id'];
          _patientName = fullName;
          _initialAssessmentCompleted = false;
          await prefs.setString('auth_patient_id', _patientId!);
          await prefs.setString('auth_patient_name', _patientName);
          await prefs.setBool('assess_completed_$_patientId', false);
        }

        notifyListeners();
        return {'success': true, 'role': _role, 'data': data};
      } else {
        final error = jsonDecode(res.body);
        return {'success': false, 'error': error['detail'] ?? 'Registration failed.'};
      }
    } catch (e) {
      // Offline fallback registration
      final localId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      if (role.toUpperCase() == 'PATIENT') {
        setPatient(id: localId, name: fullName, assessmentCompleted: false);
      } else {
        setCaregiver(id: localId, name: fullName, email: username);
      }
      return {'success': true, 'role': role.toUpperCase(), 'offline': true};
    }
  }

  Future<void> switchLanguage(String langCode) async {
    if (!['en', 'hi', 'as'].contains(langCode)) return;
    _language = langCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', langCode);
    } catch (_) {}
  }

  void logout() async {
    _token = null;
    _userId = null;
    _username = null;
    _patientId = null;
    _patientName = 'Ifra';
    _caregiverId = null;
    _caregiverName = null;
    _caregiverEmail = null;
    _role = 'Patient';
    _initialAssessmentCompleted = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_patient_id');
      await prefs.remove('auth_caregiver_id');
      await prefs.remove('auth_role');
    } catch (_) {}
  }
}

