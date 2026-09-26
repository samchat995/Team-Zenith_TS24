"""
Database seeding script for Neural Nexus.
Creates demo accounts:
- Patients: Ifra (PIN 1234), Taiba (PIN 1234), Kamala, Arun, Suresh, Meena
- Healthcare Worker: Ritasri (ritasri@neuralnexus.demo / Doctor@123)
- Caregiver: (caregiver@neuralnexus.demo / Caregiver@123)
- Admin: (admin@neuralnexus.demo / Admin@123)
Populates all 18 cognitive games, isolated game sessions, reminders, mood logs, and memory items.
"""
import sys
import os
from datetime import datetime, timedelta, timezone

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.database import SessionLocal, Base, engine
from backend.app.models import (
    User, Patient, Caregiver, HealthcareWorker, PatientAssignment,
    Game, GameSession, Reminder, MoodLog, MemoryItem, CaregiverNote, ProfessionalNote, FollowUpRecommendation, AuditLog
)
from backend.app.auth import hash_password
from adaptive_engine.recommendation_engine import RecommendationEngine


def seed_database():
    print("Initializing database tables...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    now = datetime.now(timezone.utc)

    print("Seeding 18 cognitive games...")
    rec_engine = RecommendationEngine()
    for g in rec_engine.GAMES_CATALOG:
        game_obj = Game(
            id=g["id"],
            title=g["title"],
            category=g["category"],
            description=g["desc"],
            min_level=1,
            max_level=5
        )
        db.add(game_obj)
    db.commit()

    print("Seeding User Accounts & Profiles...")
    # 1. Caregiver
    caregiver_user = User(
        username="caregiver",
        email="caregiver@neuralnexus.demo",
        hashed_password=hash_password("Caregiver@123"),
        full_name="Ananya Sharma",
        role="CAREGIVER"
    )
    db.add(caregiver_user)
    db.flush()

    caregiver_prof = Caregiver(
        user_id=caregiver_user.id,
        phone="+91 98765 43210",
        relationship_to_patient="Primary Family Caregiver"
    )
    db.add(caregiver_prof)

    # 2. Healthcare Worker (Dr. Ritasri)
    hw_user = User(
        username="ritasri",
        email="ritasri@neuralnexus.demo",
        hashed_password=hash_password("Doctor@123"),
        full_name="Dr. Ritasri",
        role="HEALTHCARE_WORKER"
    )
    db.add(hw_user)
    db.flush()

    hw_prof = HealthcareWorker(
        user_id=hw_user.id,
        professional_id="NER-HW-2026-089",
        specialization="Cognitive Health & Geriatric Care",
        hospital_clinic="Guwahati Regional Wellness Centre"
    )
    db.add(hw_prof)

    # 3. Admin
    admin_user = User(
        username="admin",
        email="admin@neuralnexus.demo",
        hashed_password=hash_password("Admin@123"),
        full_name="System Administrator",
        role="ADMIN"
    )
    db.add(admin_user)

    # 4. Patient 1: Ifra
    ifra_user = User(
        username="ifra",
        email="ifra@neuralnexus.demo",
        full_name="Ifra",
        pin="1234",
        role="PATIENT"
    )
    db.add(ifra_user)
    db.flush()

    ifra_patient = Patient(
        user_id=ifra_user.id,
        age=72,
        gender="Female",
        primary_language="en",
        emergency_contact="+91 98765 43210"
    )
    db.add(ifra_patient)

    # 5. Patient 2: Taiba
    taiba_user = User(
        username="taiba",
        email="taiba@neuralnexus.demo",
        full_name="Taiba",
        pin="1234",
        role="PATIENT"
    )
    db.add(taiba_user)
    db.flush()

    taiba_patient = Patient(
        user_id=taiba_user.id,
        age=68,
        gender="Female",
        primary_language="hi",
        emergency_contact="+91 98765 43211"
    )
    db.add(taiba_patient)

    # Additional Demo Patients for analytics variety
    demo_specs = [
        ("Kamala Devi", "kamala", 75, "as", "Stable"),
        ("Arun Barua", "arun", 70, "as", "Improving"),
        ("Suresh Das", "suresh", 80, "en", "Low Activity"),
        ("Meena Begum", "meena", 69, "hi", "Good Memory / Slower Speed")
    ]
    other_patients = []
    for name, uname, age, lang, pattern in demo_specs:
        u = User(username=uname, email=f"{uname}@neuralnexus.demo", full_name=name, pin="1234", role="PATIENT")
        db.add(u)
        db.flush()
        p = Patient(user_id=u.id, age=age, primary_language=lang)
        db.add(p)
        other_patients.append(p)

    db.commit()

    print("Assigning patients to Caregiver and Dr. Ritasri...")
    all_seeded_patients = [ifra_patient, taiba_patient] + other_patients
    for p in all_seeded_patients:
        assignment = PatientAssignment(
            patient_id=p.id,
            caregiver_id=caregiver_prof.id,
            healthcare_worker_id=hw_prof.id
        )
        db.add(assignment)

    print("Seeding Ifra's distinct activity & history...")
    # Ifra: 2 completed games today (2/4 games = 50% game progress + 1 completed reminder) -> 48% progress
    s1 = GameSession(
        patient_id=ifra_patient.id,
        game_id="remember_objects",
        category="memory",
        level=2,
        score=85,
        accuracy=88.0,
        attempts=1,
        mistakes=1,
        response_time_ms=1450,
        duration_seconds=35,
        completed=True,
        completed_at=now - timedelta(hours=3)
    )
    s2 = GameSession(
        patient_id=ifra_patient.id,
        game_id="memory_match",
        category="memory",
        level=2,
        score=90,
        accuracy=92.0,
        attempts=1,
        mistakes=1,
        response_time_ms=1600,
        duration_seconds=45,
        completed=True,
        completed_at=now - timedelta(hours=1)
    )
    db.add_all([s1, s2])

    # Ifra Reminders: 2 pending, 1 completed
    r_ifra_1 = Reminder(
        patient_id=ifra_patient.id,
        title="Afternoon Blood Pressure Medicine",
        reminder_type="medicine",
        time_of_day="02:00 PM",
        completed=False,
        notes="Take with lukewarm water after lunch."
    )
    r_ifra_2 = Reminder(
        patient_id=ifra_patient.id,
        title="Afternoon Hydration - Warm Water",
        reminder_type="hydration",
        time_of_day="04:00 PM",
        completed=False,
        notes="Drink 1 full glass of fresh water."
    )
    r_ifra_3 = Reminder(
        patient_id=ifra_patient.id,
        title="Morning Walk in the Garden",
        reminder_type="daily_activity",
        time_of_day="08:00 AM",
        completed=True,
        completed_at=now - timedelta(hours=10),
        notes="15-minute gentle stroll."
    )
    r_ifra_4 = Reminder(
        patient_id=ifra_patient.id,
        title="Dr. Ritasri Follow-Up Check-In",
        reminder_type="appointment",
        time_of_day="11:30 AM",
        completed=False,
        notes="Monthly cognitive health review."
    )
    db.add_all([r_ifra_1, r_ifra_2, r_ifra_3, r_ifra_4])

    # Ifra Mood Log
    db.add(MoodLog(
        patient_id=ifra_patient.id,
        mood="Calm",
        note="Felt very peaceful after looking at morning flowers.",
        language="en"
    ))

    # Ifra Personalized Memory Profile ("My Memory")
    m1 = MemoryItem(
        patient_id=ifra_patient.id,
        category="family",
        title="Meena",
        relationship="Granddaughter",
        details="Meena loves reading storybooks with me and brought yellow marigolds."
    )
    m2 = MemoryItem(
        patient_id=ifra_patient.id,
        category="favorite",
        title="Assam Cardamom Tea",
        details="Enjoys 1 cup of warm tea with cardamom at 4:30 PM."
    )
    m3 = MemoryItem(
        patient_id=ifra_patient.id,
        category="place",
        title="Front Porch Garden",
        details="Sitting on the wooden cane chair watching the afternoon sparrows."
    )
    m4 = MemoryItem(
        patient_id=ifra_patient.id,
        category="routine",
        title="Evening Radio Music",
        details="Listening to gentle acoustic melodies before dinner."
    )
    db.add_all([m1, m2, m3, m4])

    # Caregiver & Professional Notes for Ifra
    db.add(CaregiverNote(
        patient_id=ifra_patient.id,
        caregiver_id=caregiver_prof.id,
        note_text="Ifra had a wonderful morning and was very joyful during the memory matching game."
    ))
    db.add(ProfessionalNote(
        patient_id=ifra_patient.id,
        worker_id=hw_prof.id,
        worker_name="Dr. Ritasri",
        note_text="Patient demonstrates consistent recall on everyday objects. Responsive and relaxed.",
        clinical_observation="Visual pattern recognition is steady. Maintain current gentle difficulty."
    ))
    db.add(FollowUpRecommendation(
        patient_id=ifra_patient.id,
        worker_id=hw_prof.id,
        recommendation_text="Encourage daily hydration reminders and afternoon family photo recall.",
        priority="Normal"
    ))

    print("Seeding Taiba's distinct isolated data...")
    # Taiba: 1 completed game (Routine order), 3 pending reminders, mood "Happy"
    t_s1 = GameSession(
        patient_id=taiba_patient.id,
        game_id="routine_order",
        category="routine",
        level=1,
        score=75,
        accuracy=80.0,
        attempts=2,
        mistakes=1,
        response_time_ms=2200,
        duration_seconds=50,
        completed=True,
        completed_at=now - timedelta(hours=2)
    )
    db.add(t_s1)

    r_taiba_1 = Reminder(
        patient_id=taiba_patient.id,
        title="Vitamin Supplement",
        reminder_type="medicine",
        time_of_day="10:00 AM",
        completed=False,
        notes="Take after breakfast."
    )
    r_taiba_2 = Reminder(
        patient_id=taiba_patient.id,
        title="Drink Coconut Water",
        reminder_type="hydration",
        time_of_day="01:30 PM",
        completed=False
    )
    db.add_all([r_taiba_1, r_taiba_2])

    db.add(MoodLog(
        patient_id=taiba_patient.id,
        mood="Happy",
        note="Taiba enjoyed speaking to her son over phone.",
        language="hi"
    ))

    db.add(MemoryItem(
        patient_id=taiba_patient.id,
        category="family",
        title="Farhan",
        relationship="Son",
        details="Farhan is an engineer in Guwahati who calls every evening."
    ))
    db.add(MemoryItem(
        patient_id=taiba_patient.id,
        category="favorite",
        title="Fresh Guava & Pomegranate",
        details="Favorite fresh fruits cut in small slices."
    ))

    db.add(CaregiverNote(
        patient_id=taiba_patient.id,
        caregiver_id=caregiver_prof.id,
        note_text="Taiba completed her routine sequence game with patience."
    ))
    db.add(ProfessionalNote(
        patient_id=taiba_patient.id,
        worker_id=hw_prof.id,
        worker_name="Dr. Ritasri",
        note_text="Good engagement with sequence tasks. Encouraged daily routine recall.",
        clinical_observation="Responses are calm and deliberate."
    ))

    # Audit logs
    db.add(AuditLog(action="SEED_DATABASE", resource="system", details="Demo data seeded successfully"))

    db.commit()
    db.close()
    print("Seeding completed successfully!")


if __name__ == "__main__":
    seed_database()
