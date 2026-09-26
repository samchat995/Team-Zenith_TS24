"""
Authentication endpoints for Neural Nexus.
Supports:
- 4-digit PIN login for elderly patients (Ifra, Taiba)
- Email + password for Caregiver, Healthcare Worker (Ritasri), and Admin
- Complete audit logging
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, Patient, Caregiver, PatientAssignment, AuditLog
from ..schemas import TokenResponse, PatientPinLogin, StaffLogin, UserRegister
from ..auth import verify_password, hash_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse)
def register_user(payload: UserRegister, db: Session = Depends(get_db)):
    """
    Registers a new Patient or Caregiver account backed by database.
    """
    username_clean = payload.username.strip()
    if not username_clean:
        raise HTTPException(status_code=400, detail="Username cannot be empty.")

    # Check username collision
    existing_user = db.query(User).filter(User.username.ilike(username_clean)).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists. Please choose another username.")

    email_clean = payload.email.strip().lower() if payload.email else f"{username_clean.lower()}@neuralnexus.app"
    existing_email = db.query(User).filter(User.email == email_clean).first()
    if existing_email:
        email_clean = f"{username_clean.lower()}_{int(db.query(User).count())}@neuralnexus.app"

    role_clean = payload.role.strip().upper()
    if role_clean not in ["PATIENT", "CAREGIVER", "HEALTHCARE_WORKER", "ADMIN"]:
        role_clean = "PATIENT"

    new_user = User(
        username=username_clean,
        email=email_clean,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name.strip() or username_clean,
        role=role_clean,
        is_active=True,
    )
    db.add(new_user)
    db.flush()

    patient_id = None
    if role_clean == "PATIENT":
        patient = Patient(
            user_id=new_user.id,
            age=payload.age or 70,
            gender=payload.gender or "Female",
            primary_language=payload.primary_language or "en",
            emergency_contact=payload.emergency_contact,
            initial_assessment_completed=False,
        )
        db.add(patient)
        db.flush()
        patient_id = patient.id

        # Assign caregiver
        cg_id = payload.caregiver_id
        if not cg_id:
            # Check for existing caregiver to associate by default
            first_cg = db.query(Caregiver).first()
            if first_cg:
                cg_id = first_cg.id
        if cg_id:
            assignment = PatientAssignment(
                patient_id=patient.id,
                caregiver_id=cg_id,
            )
            db.add(assignment)

    elif role_clean == "CAREGIVER":
        caregiver = Caregiver(
            user_id=new_user.id,
            phone=payload.phone or "",
            relationship_to_patient="Family Caregiver",
        )
        db.add(caregiver)
        db.flush()

    # Audit log
    db.add(AuditLog(
        user_id=new_user.id,
        username=new_user.username,
        role=new_user.role,
        action="USER_REGISTER",
        resource="auth",
        details=f"New {new_user.role} account registered: {new_user.full_name} ({new_user.username})"
    ))
    db.commit()

    token = create_access_token({
        "sub": new_user.id,
        "role": new_user.role,
        "name": new_user.full_name,
        "patient_id": patient_id
    })
    return TokenResponse(
        access_token=token,
        user_id=new_user.id,
        role=new_user.role,
        full_name=new_user.full_name,
        patient_id=patient_id
    )


@router.post("/patient-login", response_model=TokenResponse)
def patient_pin_login(payload: PatientPinLogin, db: Session = Depends(get_db)):
    """
    Simplified PIN-based login for elderly patients.
    Accepts patient name (e.g. 'Ifra' or 'Taiba') and 4-digit PIN (e.g. '1234').
    """
    query_name = payload.name_or_id.strip()
    user = db.query(User).filter(
        User.role == "PATIENT",
        (User.username.ilike(query_name) | User.full_name.ilike(f"%{query_name}%"))
    ).first()

    if not user or user.pin != payload.pin.strip():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid patient name or PIN. Please enter your 4-digit PIN."
        )

    patient_record = db.query(Patient).filter(Patient.user_id == user.id).first()
    patient_id = patient_record.id if patient_record else None

    # Audit log
    db.add(AuditLog(
        user_id=user.id,
        username=user.username,
        role=user.role,
        action="PATIENT_LOGIN",
        resource="auth",
        details=f"Patient {user.full_name} logged in via PIN"
    ))
    db.commit()

    token = create_access_token({"sub": user.id, "role": user.role, "name": user.full_name, "patient_id": patient_id})
    return TokenResponse(
        access_token=token,
        user_id=user.id,
        role=user.role,
        full_name=user.full_name,
        patient_id=patient_id
    )


@router.post("/login", response_model=TokenResponse)
def staff_or_user_login(payload: StaffLogin, db: Session = Depends(get_db)):
    """
    Database-backed login for Patients, Caregivers, Healthcare Workers, and Admins.
    Accepts username or email along with password.
    """
    identifier_clean = payload.email.strip()
    user = db.query(User).filter(
        (User.email.ilike(identifier_clean)) | (User.username.ilike(identifier_clean))
    ).first()

    if not user or not user.hashed_password or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password."
        )

    patient_id = None
    if user.role == "PATIENT":
        p = db.query(Patient).filter(Patient.user_id == user.id).first()
        patient_id = p.id if p else None

    # Audit log
    db.add(AuditLog(
        user_id=user.id,
        username=user.username,
        role=user.role,
        action="USER_LOGIN",
        resource="auth",
        details=f"{user.role} {user.full_name} ({user.username}) logged in"
    ))
    db.commit()

    token = create_access_token({"sub": user.id, "role": user.role, "name": user.full_name, "patient_id": patient_id})
    return TokenResponse(
        access_token=token,
        user_id=user.id,
        role=user.role,
        full_name=user.full_name,
        patient_id=patient_id
    )

