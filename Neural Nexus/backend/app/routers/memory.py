"""
Personalized Memory Profile router for Neural Nexus ('My Memory' feature).
Allows caregivers to add family members, favourite foods, places, and routines.
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, Patient, MemoryItem
from ..schemas import MemoryItemCreate, MemoryItemOut
from ..auth import get_current_user

router = APIRouter(prefix="/memory", tags=["Memory Profile"])


@router.get("", response_model=List[MemoryItemOut])
def get_memory_items(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    items = db.query(MemoryItem).filter(
        MemoryItem.patient_id == patient_id
    ).order_by(MemoryItem.created_at.asc()).all()
    return items


@router.post("", response_model=MemoryItemOut)
def create_memory_item(
    payload: MemoryItemCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    new_item = MemoryItem(
        patient_id=payload.patient_id,
        category=payload.category,
        title=payload.title,
        details=payload.details,
        relationship=payload.relationship,
        image_url=payload.image_url
    )
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item
