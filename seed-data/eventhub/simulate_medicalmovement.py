"""Stream synthetic patient movement events to Event Hub `medicalmovement`.

Schema (must match M3 KQL `HospitalMovement` table exactly):
    patient_id, age, gender, diagnosis_code, diagnosis_desc,
    event_type, from_location, to_location, floor, timestamp

Env vars:
    EVENTHUB_MOVEMENT_CONN_STR  (full connection string with EntityPath=medicalmovement)
    SIM_DURATION_SECONDS        (optional, default 600)
    SIM_INTERVAL_SECONDS        (optional, default 5.0)
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


DIAGNOSES = [
    ("I21.9",   "Acute myocardial infarction"),
    ("J18.9",   "Pneumonia"),
    ("E11.9",   "Type 2 diabetes mellitus"),
    ("J44.1",   "COPD exacerbation"),
    ("N17.9",   "Acute kidney injury"),
    ("I50.9",   "Heart failure"),
    ("R65.20",  "Severe sepsis"),
    ("S72.001A","Femur fracture"),
]
EVENT_TYPES = ["admit", "transfer", "discharge", "imaging", "surgery"]
GENDERS = ["F", "M"]
EXTERNAL_LOCATIONS = ["AMB-IN", "ED-WAITING", "DISCHARGE-HOME", "IMAGING-RAD", "OR-3"]


def floor_for_ward(ward_code: str) -> str:
    return {
        "ER": "1", "OBS": "1",
        "ICU": "5",
        "MED": "3",
        "PED": "4",
        "OB": "6",
    }.get(ward_code, "2")


def main() -> None:
    conn_str = os.environ.get("EVENTHUB_MOVEMENT_CONN_STR")
    if not conn_str:
        sys.exit("EVENTHUB_MOVEMENT_CONN_STR not set")

    duration = float(os.environ.get("SIM_DURATION_SECONDS", "600"))
    interval = float(os.environ.get("SIM_INTERVAL_SECONDS", "5.0"))

    ids = load_ids()
    wards = expand_wards(ids)
    wards_by_hospital: dict[str, list[dict]] = {}
    for w in wards:
        wards_by_hospital.setdefault(w["hospitalId"], []).append(w)
    patients = patient_ids(ids)

    producer = EventHubProducerClient.from_connection_string(conn_str)
    print(f"Streaming medicalmovement for {duration}s every {interval}s")

    end = time.time() + duration
    n = 0
    try:
        while time.time() < end:
            batch = producer.create_batch()
            for _ in range(random.randint(1, 3)):
                pid, hid = random.choice(patients)
                src = random.choice(wards_by_hospital[hid])
                dst = random.choice(wards_by_hospital[hid])
                event_type = random.choice(EVENT_TYPES)
                if event_type == "admit":
                    from_loc = random.choice(EXTERNAL_LOCATIONS)
                    to_loc = src["wardId"]
                    floor = floor_for_ward(src["code"])
                elif event_type == "discharge":
                    from_loc = src["wardId"]
                    to_loc = random.choice(EXTERNAL_LOCATIONS)
                    floor = floor_for_ward(src["code"])
                else:
                    from_loc = src["wardId"]
                    to_loc = dst["wardId"]
                    floor = floor_for_ward(dst["code"])

                diag_code, diag_desc = random.choice(DIAGNOSES)
                evt = {
                    "patient_id":     pid,
                    "age":            random.randint(18, 92),
                    "gender":         random.choice(GENDERS),
                    "diagnosis_code": diag_code,
                    "diagnosis_desc": diag_desc,
                    "event_type":     event_type,
                    "from_location":  from_loc,
                    "to_location":    to_loc,
                    "floor":          floor,
                    "timestamp":      datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
                    "_hospitalId":    hid,
                }
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
