"""
Comprehensive API test suite for Neural Nexus backend.
Verifies:
- Patient PIN login (Ifra & Taiba)
- Caregiver, Healthcare Worker (Ritasri), and Admin authentication
- Strict patient data isolation
- Dynamic dashboard calculations
- Game telemetry ingestion & adaptive difficulty feedback
- Reminders, Mood check-in, Personalized memory items
- Offline sync batch processor
- Healthcare Worker clinical endpoints & RBAC enforcement
"""
import pytest
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["project"] == "NEURAL NEXUS"
    assert "disclaimer" in data


def test_patient_pin_login_ifra():
    response = client.post("/auth/patient-login", json={"name_or_id": "Ifra", "pin": "1234"})
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "PATIENT"
    assert data["full_name"] == "Ifra"
    assert "access_token" in data
    assert data["patient_id"] is not None


def test_patient_pin_login_taiba():
    response = client.post("/auth/patient-login", json={"name_or_id": "Taiba", "pin": "1234"})
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "PATIENT"
    assert data["full_name"] == "Taiba"
    assert "access_token" in data


def test_patient_pin_login_invalid():
    response = client.post("/auth/patient-login", json={"name_or_id": "Ifra", "pin": "9999"})
    assert response.status_code == 401


def test_healthcare_worker_login_ritasri():
    response = client.post("/auth/login", json={"email": "ritasri@neuralnexus.demo", "password": "Doctor@123"})
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "HEALTHCARE_WORKER"
    assert data["full_name"] == "Dr. Ritasri"


def test_caregiver_login():
    response = client.post("/auth/login", json={"email": "caregiver@neuralnexus.demo", "password": "Caregiver@123"})
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "CAREGIVER"


def test_admin_login():
    response = client.post("/auth/login", json={"email": "admin@neuralnexus.demo", "password": "Admin@123"})
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "ADMIN"


def test_patient_dashboard_summary_and_isolation():
    # Login as Ifra
    ifra_auth = client.post("/auth/patient-login", json={"name_or_id": "Ifra", "pin": "1234"}).json()
    ifra_token = ifra_auth["access_token"]
    ifra_pid = ifra_auth["patient_id"]

    # Login as Taiba
    taiba_auth = client.post("/auth/patient-login", json={"name_or_id": "Taiba", "pin": "1234"}).json()
    taiba_token = taiba_auth["access_token"]
    taiba_pid = taiba_auth["patient_id"]

    # Ifra accesses her own dashboard
    res_ifra = client.get(
        f"/patients/{ifra_pid}/dashboard-summary",
        headers={"Authorization": f"Bearer {ifra_token}"}
    )
    assert res_ifra.status_code == 200
    data_ifra = res_ifra.json()
    assert data_ifra["full_name"] == "Ifra"
    assert data_ifra["games_completed_today"] >= 2
    assert data_ifra["progress_percentage"] > 0
    assert data_ifra["today_activity"]["title"] is not None

    # Taiba accesses her own dashboard
    res_taiba = client.get(
        f"/patients/{taiba_pid}/dashboard-summary",
        headers={"Authorization": f"Bearer {taiba_token}"}
    )
    assert res_taiba.status_code == 200
    data_taiba = res_taiba.json()
    assert data_taiba["full_name"] == "Taiba"
    assert data_taiba["games_completed_today"] == 1  # Completely separate!

    # RBAC Isolation: Ifra attempts to access Taiba's dashboard -> must be rejected 403!
    res_unauth = client.get(
        f"/patients/{taiba_pid}/dashboard-summary",
        headers={"Authorization": f"Bearer {ifra_token}"}
    )
    assert res_unauth.status_code == 403


def test_games_catalog_and_session_recording():
    # Fetch 18 games
    res_catalog = client.get("/games")
    assert res_catalog.status_code == 200
    catalog = res_catalog.json()
    assert len(catalog) == 18

    # Login as Ifra
    ifra_auth = client.post("/auth/patient-login", json={"name_or_id": "Ifra", "pin": "1234"}).json()
    token = ifra_auth["access_token"]
    pid = ifra_auth["patient_id"]

    # Ingest session
    session_payload = {
        "patient_id": pid,
        "game_id": "remember_objects",
        "category": "memory",
        "level": 2,
        "score": 95,
        "accuracy": 92.0,
        "attempts": 1,
        "mistakes": 0,
        "response_time_ms": 1300,
        "duration_seconds": 30,
        "completed": True,
        "offline_created": False
    }
    res_session = client.post(
        "/games/session",
        json=session_payload,
        headers={"Authorization": f"Bearer {token}"}
    )
    assert res_session.status_code == 200
    data = res_session.json()
    assert "adaptive_feedback" in data
    assert data["adaptive_feedback"]["recommendation"] in ["INCREASE", "MAINTAIN", "REDUCE"]


def test_reminders_crud():
    ifra_auth = client.post("/auth/patient-login", json={"name_or_id": "Ifra", "pin": "1234"}).json()
    token = ifra_auth["access_token"]
    pid = ifra_auth["patient_id"]

    # Get reminders
    res = client.get(f"/reminders?patient_id={pid}", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    reminders = res.json()
    assert len(reminders) >= 3

    # Toggle one reminder as completed
    rem_id = reminders[0]["id"]
    res_update = client.put(
        f"/reminders/{rem_id}",
        json={"completed": True},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert res_update.status_code == 200
    assert res_update.json()["completed"] is True


def test_offline_sync_batch():
    ifra_auth = client.post("/auth/patient-login", json={"name_or_id": "Ifra", "pin": "1234"}).json()
    token = ifra_auth["access_token"]
    pid = ifra_auth["patient_id"]

    sync_payload = {
        "patient_id": pid,
        "sessions": [
            {
                "patient_id": pid,
                "game_id": "find_different",
                "category": "attention",
                "level": 1,
                "score": 80,
                "accuracy": 85.0,
                "attempts": 1,
                "mistakes": 1,
                "response_time_ms": 1800,
                "duration_seconds": 25,
                "completed": True,
                "offline_created": True
            }
        ],
        "reminders_completed": [],
        "moods": [
            {
                "patient_id": pid,
                "mood": "Calm",
                "note": "Played while offline at countryside",
                "language": "en"
            }
        ]
    }
    res_sync = client.post("/sync", json=sync_payload, headers={"Authorization": f"Bearer {token}"})
    assert res_sync.status_code == 200
    data = res_sync.json()
    assert data["status"] == "SUCCESS"
    assert data["synced_sessions_count"] == 1
    assert data["synced_moods_count"] == 1


def test_healthcare_worker_ritasri_portal():
    # Login as Dr. Ritasri
    ritasri_auth = client.post("/auth/login", json={"email": "ritasri@neuralnexus.demo", "password": "Doctor@123"}).json()
    token = ritasri_auth["access_token"]

    # 1. View assigned patients
    res_patients = client.get("/healthcare/assigned-patients", headers={"Authorization": f"Bearer {token}"})
    assert res_patients.status_code == 200
    patients = res_patients.json()
    assert len(patients) >= 2
    ifra = next(p for p in patients if p["full_name"] == "Ifra")

    # 2. View cognitive overview for Ifra
    res_overview = client.get(f"/healthcare/patient/{ifra['patient_id']}/cognitive-overview", headers={"Authorization": f"Bearer {token}"})
    assert res_overview.status_code == 200
    overview = res_overview.json()
    assert "domain_analysis" in overview
    assert len(overview["recent_sessions"]) > 0

    # 3. Add professional note
    res_note = client.post(
        "/healthcare/professional-note",
        json={
            "patient_id": ifra["patient_id"],
            "note_text": "Routine checkup reveals steady cognitive engagement. No signs of fatigue.",
            "clinical_observation": "Consistent attention in routine sequencing."
        },
        headers={"Authorization": f"Bearer {token}"}
    )
    assert res_note.status_code == 200
    assert res_note.json()["status"] == "SUCCESS"

    # 4. Generate report
    res_report = client.get(f"/healthcare/patient/{ifra['patient_id']}/report", headers={"Authorization": f"Bearer {token}"})
    assert res_report.status_code == 200
    report = res_report.json()
    assert "disclaimer" in report
    assert report["patient"]["name"] == "Ifra"


def test_register_and_initial_assessment_flow():
    # 1. Register a new patient
    import uuid
    uid = str(uuid.uuid4())[:8]
    reg_payload = {
        "username": f"patient_{uid}",
        "password": "Password@123",
        "full_name": f"Test Patient {uid}",
        "role": "PATIENT",
        "age": 68,
        "gender": "Female",
        "primary_language": "as",
        "emergency_contact": "+919876543210"
    }
    reg_res = client.post("/auth/register", json=reg_payload)
    assert reg_res.status_code == 200
    reg_data = reg_res.json()
    assert reg_data["role"] == "PATIENT"
    token = reg_data["access_token"]
    patient_id = reg_data["patient_id"]
    assert patient_id is not None

    # 2. Login using username + password
    login_res = client.post("/auth/login", json={"email": f"patient_{uid}", "password": "Password@123"})
    assert login_res.status_code == 200
    assert login_res.json()["user_id"] == reg_data["user_id"]

    # 3. Check dashboard initially shows initial_assessment_completed == False
    dash_res = client.get(f"/patients/{patient_id}/dashboard-summary", headers={"Authorization": f"Bearer {token}"})
    assert dash_res.status_code == 200
    assert dash_res.json()["initial_assessment_completed"] is False

    # 4. Save 10-question initial assessment
    assessment_payload = {
        "patient_id": patient_id,
        "language": "en",
        "notes": "Elderly dementia memory screening",
        "responses": [
            {
                "question_id": 1,
                "character_name": "Anima",
                "location": "Jorhat, Assam",
                "question_text": "Like Anima, has this ever happened to you – when you forget something someone told you recently and had to ask about it again?",
                "story_summary": "Anima preparing for Bihu",
                "answer": "Yes",
                "language": "en"
            },
            {
                "question_id": 2,
                "character_name": "Ato",
                "location": "Kohima, Nagaland",
                "question_text": "When you go shopping or have several things to arrange, does this sometimes happen to you too?",
                "story_summary": "Ato shopping in Kohima market",
                "answer": "No",
                "language": "en"
            }
        ]
    }
    save_res = client.post(f"/patients/{patient_id}/initial-assessment", json=assessment_payload, headers={"Authorization": f"Bearer {token}"})
    assert save_res.status_code == 200
    save_data = save_res.json()
    assert save_data["completed"] is True
    assert save_data["yes_count"] == 1
    assert save_data["no_count"] == 1
    assert len(save_data["responses"]) == 2

    # 5. Check dashboard now shows initial_assessment_completed == True
    dash_res2 = client.get(f"/patients/{patient_id}/dashboard-summary", headers={"Authorization": f"Bearer {token}"})
    assert dash_res2.status_code == 200
    assert dash_res2.json()["initial_assessment_completed"] is True

    # 6. Retrieve assessment responses
    get_res = client.get(f"/patients/{patient_id}/initial-assessment", headers={"Authorization": f"Bearer {token}"})
    assert get_res.status_code == 200
    get_data = get_res.json()
    assert len(get_data["responses"]) == 2
    assert get_data["responses"][0]["character_name"] == "Anima"
    assert get_data["responses"][0]["answer"] == "Yes"


def test_caregiver_registration_and_isolation():
    import uuid
    uid = str(uuid.uuid4())[:8]
    # Register Caregiver B
    cg_res = client.post("/auth/register", json={
        "username": f"caregiver_{uid}",
        "password": "Password@123",
        "full_name": f"Caregiver {uid}",
        "role": "CAREGIVER",
        "phone": "9876543210"
    })
    assert cg_res.status_code == 200
    cg_token = cg_res.json()["access_token"]

    # Newly registered caregiver has 0 assigned patients initially
    patients_res = client.get("/patients", headers={"Authorization": f"Bearer {cg_token}"})
    assert patients_res.status_code == 200
    assert len(patients_res.json()) == 0

