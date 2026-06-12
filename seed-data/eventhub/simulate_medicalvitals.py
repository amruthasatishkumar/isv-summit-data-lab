"""Stream synthetic patient vitals to Event Hub `medicalvitals`.

Schema (must match M3 KQL `HospitalVitals` table exactly):
    patient_id, age, gender, diagnosis_code, condition,
    heart_rate, bp_systolic, bp_diastolic, temperature_f,
    spo2, respiratory_rate, timestamp

Env vars:
    EVENTHUB_VITALS_CONN_STR  (full connection string with EntityPath=medicalvitals)
    SIM_DURATION_SECONDS      (optional, default 600)
    SIM_INTERVAL_SECONDS      (optional, default 1.0)
"""
from __future__ import annotations
import json
import os
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

try:
    from azure.eventhub import EventHubProducerClient, EventData
except ImportError:
    sys.exit("azure-eventhub not installed. Run: pip install azure-eventhub")

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from shared._loader import load_ids, expand_wards, patient_ids  # noqa: E402


# ICD-10-ish codes paired with human-readable conditions (synthetic)
DIAGNOSES = [
    ("I21.9", "Acute myocardial infarction"),
    ("J18.9", "Pneumonia, unspecified"),
    ("E11.9", "Type 2 diabetes mellitus"),
    ("J44.1", "COPD with acute exacerbation"),
    ("N17.9", "Acute kidney injury"),
    ("I50.9", "Heart failure, unspecified"),
    ("R65.20", "Severe sepsis"),
    ("S72.001A", "Femur fracture"),
]
GENDERS = ["F", "M"]


def make_event(patient_id: str, hospital_id: str, ward_id: str) -> dict:
    diag_code, condition = random.choice(DIAGNOSES)
    # Most patients stable; occasionally spike values to trigger M3 alerts
    spike = random.random() < 0.07
    return {
        "patient_id":       patient_id,
        "age":              random.randint(18, 92),
        "gender":           random.choice(GENDERS),
        "diagnosis_code":   diag_code,
        "condition":        condition,
        "heart_rate":       random.randint(140, 165) if spike else random.randint(58, 100),
        "bp_systolic":      random.randint(150, 195) if spike else random.randint(105, 138),
        "bp_diastolic":     random.randint(95, 115)  if spike else random.randint(65, 88),
        "temperature_f":    round(random.uniform(101.5, 104.0), 1) if spike else round(random.uniform(97.5, 99.4), 1),
        "spo2":             random.randint(80, 88)   if spike else random.randint(94, 100),
        "respiratory_rate": random.randint(24, 32)   if spike else random.randint(12, 20),
        "timestamp":        datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        # ---- Application properties (not in KQL schema, but useful for routing/joins) ----
        "_hospitalId":      hospital_id,
        "_wardId":          ward_id,
    }


def main() -> None:
    conn_str = os.environ.get("EVENTHUB_VITALS_CONN_STR")
    if not conn_str:
        sys.exit("EVENTHUB_VITALS_CONN_STR not set")

    duration = float(os.environ.get("SIM_DURATION_SECONDS", "600"))
    interval = float(os.environ.get("SIM_INTERVAL_SECONDS", "1.0"))

    ids = load_ids()
    wards_by_hospital: dict[str, list[str]] = {}
    for w in expand_wards(ids):
        wards_by_hospital.setdefault(w["hospitalId"], []).append(w["wardId"])
    patients = patient_ids(ids)

    producer = EventHubProducerClient.from_connection_string(conn_str)
    print(f"Streaming medicalvitals for {duration}s every {interval}s "
          f"(patients={len(patients)})")

    end = time.time() + duration
    n = 0
    try:
        while time.time() < end:
            batch = producer.create_batch()
            for _ in range(random.randint(2, 5)):
                pid, hid = random.choice(patients)
                wid = random.choice(wards_by_hospital[hid])
                evt = make_event(pid, hid, wid)
                batch.add(EventData(json.dumps(evt)))
            producer.send_batch(batch)
            n += len(batch)
            time.sleep(interval)
    except KeyboardInterrupt:
        print("Interrupted by user.")
    finally:
        producer.close()
        print(f"Sent {n} events.")


if __name__ == "__main__":
    main()
