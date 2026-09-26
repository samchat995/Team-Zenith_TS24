"""
Database engine and session configuration for Neural Nexus.
Uses SQLite for zero-configuration local execution and can point to PostgreSQL via DATABASE_URL.
"""
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./neural_nexus.db")

# SQLite needs check_same_thread=False
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def run_sqlite_migrations():
    """Ensures newly added columns exist in existing SQLite databases without requiring table reset."""
    try:
        with engine.connect() as conn:
            res = conn.exec_driver_sql("PRAGMA table_info(patients)").fetchall()
            col_names = [r[1] for r in res]
            if "initial_assessment_completed" not in col_names and len(col_names) > 0:
                conn.exec_driver_sql("ALTER TABLE patients ADD COLUMN initial_assessment_completed BOOLEAN DEFAULT 0")
                conn.commit()
    except Exception:
        pass


run_sqlite_migrations()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

