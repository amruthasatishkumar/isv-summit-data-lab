"""Generate facility_catalog.parquet from shared/ids.json.

Output: seed-data/parquet/output/facility_catalog.parquet

Schema:
    facility_id (string)        -- e.g. H-1
    facility_name (string)
    facility_type (string)      -- Tertiary | Academic | Community | Specialty
    region_id (string)
    region_name (string)
    photo_path (string)         -- relative path: facilities/<facility_id>.jpg
    beds_total (int32)
    beds_icu (int32)
    accreditation (string)
    opened_year (int16)
    address (string)

The first N hospitals come from shared/ids.json (so the streaming sims keep
working). The rest are synthetic but deterministic - same Faker seed -> same
parquet every time. TARGET_ROWS aligns with the SQL seed (100 hospitals).
"""
from __future__ import annotations
import sys
from pathlib import Path

import pandas as pd
from faker import Faker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from shared._loader import load_ids  # noqa: E402

fake = Faker("en_US")
Faker.seed(42)

ACCRED = ["Joint Commission Accredited", "DNV GL Accredited", "Magnet Recognized", "CMS 5-Star"]
FACILITY_TYPES = ["Tertiary", "Academic", "Community", "Specialty"]
NAME_SUFFIXES = [
    "Medical Center", "General Hospital", "Community Hospital", "Regional Health",
    "Memorial Hospital", "University Medical", "Health Pavilion", "Specialty Center",
    "Urgent Care Center", "Children's Hospital",
]
NAME_PREFIXES = [
    "Maple", "Cedar", "Oak", "Pine", "Birch", "Elm", "Willow", "Aspen",
    "Hawthorn", "Sycamore", "Cypress", "Sequoia", "Magnolia", "Juniper",
    "Walnut", "Chestnut", "Poplar", "Spruce", "Cottonwood", "Beech",
]

TARGET_ROWS = 100


def main() -> None:
    ids = load_ids()
    region_lookup = {r["regionId"]: r["name"] for r in ids["regions"]}
    region_ids = list(region_lookup.keys())

    rows = []

    # Real UrbanPulse hospitals (first 5) - keep their IDs / names.
    for h in ids["hospitals"]:
        rows.append({
            "facility_id":   h["hospitalId"],
            "facility_name": h["name"],
            "facility_type": h["type"],
            "region_id":     h["regionId"],
            "region_name":   region_lookup[h["regionId"]],
            "photo_path":    f"facilities/{h['hospitalId']}.jpg",
            "beds_total":    int(h["beds"]),
            "beds_icu":      int(h["icuBeds"]),
            "accreditation": ACCRED[hash(h["hospitalId"]) % len(ACCRED)],
            "opened_year":   int(h["opened"]),
            "address":       fake.street_address() + ", Metropolis",
        })

    # Synthetic facilities to reach TARGET_ROWS - aligns with H-6..H-100 in SQL seed.
    next_idx = len(rows) + 1
    while len(rows) < TARGET_ROWS:
        facility_id = f"H-{next_idx}"
        facility_type = FACILITY_TYPES[next_idx % len(FACILITY_TYPES)]
        region_id = region_ids[next_idx % len(region_ids)]
        prefix = NAME_PREFIXES[next_idx % len(NAME_PREFIXES)]
        suffix = NAME_SUFFIXES[(next_idx * 3) % len(NAME_SUFFIXES)]
        rows.append({
            "facility_id":   facility_id,
            "facility_name": f"{prefix} {suffix}",
            "facility_type": facility_type,
            "region_id":     region_id,
            "region_name":   region_lookup[region_id],
            "photo_path":    f"facilities/{facility_id}.jpg",
            "beds_total":    60 + ((next_idx * 17) % 580),
            "beds_icu":      6  + ((next_idx * 3)  % 80),
            "accreditation": ACCRED[next_idx % len(ACCRED)],
            "opened_year":   1925 + ((next_idx * 11) % 100),
            "address":       fake.street_address() + ", Metropolis",
        })
        next_idx += 1

    df = pd.DataFrame(rows)
    df = df.astype({
        "beds_total":  "int32",
        "beds_icu":    "int32",
        "opened_year": "int16",
    })

    out_dir = Path(__file__).resolve().parent / "output"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "facility_catalog.parquet"
    df.to_parquet(out_path, index=False, engine="pyarrow", compression="snappy")

    print(f"Wrote {out_path}  ({len(df)} rows, {out_path.stat().st_size:,} bytes)")
    print(df.head(10).to_string(index=False))
    print(f"... ({len(df) - 10} more rows)")


if __name__ == "__main__":
    main()
