# backend/app/__init__.py
import sys
from pathlib import Path

# Ensure project root containing 'adaptive_engine' is discoverable on sys.path
_project_root = str(Path(__file__).resolve().parent.parent.parent)
if _project_root not in sys.path:
    sys.path.insert(0, _project_root)
