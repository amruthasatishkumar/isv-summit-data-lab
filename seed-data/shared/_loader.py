"""Tiny helper used by every generator/simulator to load shared IDs."""
from __future__ import annotations
import json
from pathlib import Path
from typing import Any


def _ids_path() -> Path:
    here = Path(__file__).resolve()
    # seed-data/shared/_loader.py  ->  ../shared/ids.json
    return here.parent / "ids.json"


def load_ids() -> dict[str, Any]:
    """Load the canonical seed-data ID catalog."""
    with _ids_path().open("r", encoding="utf-8") as f:
        return json.load(f)


def expand_wards(ids: dict[str, Any]) -> list[dict[str, Any]]:
    """Materialize the cartesian product of hospitals x wardTypes into ward rows."""
    out = []
    for h_idx, h in enumerate(ids["hospitals"], start=1):
        for w_seq, wt in enumerate(ids["wardTypes"], start=1):
            ward_id = f"W-{h_idx}{w_seq:02d}"
            out.append({
                "wardId": ward_id,
                "hospitalId": h["hospitalId"],
                "code": wt["code"],
                "name": wt["name"],
                "capacity": wt["beds"],
            })
    return out


def patient_ids(ids: dict[str, Any]) -> list[tuple[str, str]]:
    """Return list of (patientId, hospitalId) pairs."""
    per = ids["patients"]["perHospital"]
    out = []
    for h_idx, h in enumerate(ids["hospitals"], start=1):
        for p in range(1, per + 1):
            out.append((f"P-{h_idx}-{p:03d}", h["hospitalId"]))
    return out
