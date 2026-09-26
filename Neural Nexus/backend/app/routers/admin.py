"""
Admin router for Neural Nexus.
Provides user management, role management, and audit log inspection.
Restricted exclusively to ADMIN role.
"""
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, Patient, Caregiver, HealthcareWorker, AuditLog
from ..auth import get_current_user, require_roles

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/users", dependencies=[Depends(require_roles("ADMIN"))])
def get_all_users(db: Session = Depends(get_db)):
    """Lists all users across the system."""
    users = db.query(User).all()
    return [
        {
            "id": u.id,
            "username": u.username,
            "email": u.email,
            "full_name": u.full_name,
            "role": u.role,
            "is_active": u.is_active,
            "created_at": u.created_at
        } for u in users
    ]


@router.get("/audit-logs", dependencies=[Depends(require_roles("ADMIN"))])
def get_audit_logs(limit: int = 50, db: Session = Depends(get_db)):
    """Retrieves recent audit logs."""
    logs = db.query(AuditLog).order_by(AuditLog.timestamp.desc()).limit(limit).all()
    return [
        {
            "id": l.id,
            "user_id": l.user_id,
            "username": l.username,
            "role": l.role,
            "action": l.action,
            "resource": l.resource,
            "details": l.details,
            "timestamp": l.timestamp
        } for l in logs
    ]
