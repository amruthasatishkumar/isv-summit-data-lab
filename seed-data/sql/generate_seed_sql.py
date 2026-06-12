"""Generate seed-data/sql/02_seed.sql from shared/ids.json.

Deterministic: same Faker seed -> same SQL every time.
Run after any change to ids.json.
"""
from __future__ import annotations
import sys
from datetime import date, timedelta
from pathlib import Path

from faker import Faker

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from shared._loader import load_ids, expand_wards  # noqa: E402

fake = Faker("en_US")
Faker.seed(42)

# Mix per hospital: 8 nurses, 6 physicians, 4 techs, 4 EMS, 4 admin, 4 housekeeping = 30
ROLE_MIX = [
    ("Nurse",        8),
    ("Physician",    6),
    ("Tech",         4),
    ("EMS",          4),
    ("Admin",        4),
    ("Housekeeping", 4),
]
SHIFTS = ["Day", "Night", "Swing"]


def sql_str(s: str) -> str:
    return "N'" + s.replace("'", "''") + "'"


def main() -> None:
    ids = load_ids()
    wards = expand_wards(ids)

    lines: list[str] = []
    lines.append("-- =============================================================")
    lines.append("-- UrbanPulse seed data. Generated from seed-data/shared/ids.json.")
    lines.append("-- Re-run by: python seed-data\\sql\\generate_seed_sql.py")
    lines.append("-- =============================================================")
    lines.append("SET NOCOUNT ON;")
    lines.append("BEGIN TRANSACTION;")
    lines.append("")
    lines.append("DELETE FROM dbo.Staff;")
    lines.append("DELETE FROM dbo.Wards;")
    lines.append("DELETE FROM dbo.Hospitals;")
    lines.append("")

    # ---- Hospitals ----
    lines.append("-- Hospitals")
    for h in ids["hospitals"]:
        addr = fake.street_address() + ", Metropolis"
        lines.append(
            f"INSERT INTO dbo.Hospitals (hospitalId, name, regionId, facilityType, beds, icuBeds, openedYear, address) VALUES ("
            f"'{h['hospitalId']}', {sql_str(h['name'])}, '{h['regionId']}', '{h['type']}', "
            f"{h['beds']}, {h['icuBeds']}, {h['opened']}, {sql_str(addr)});"
        )
    lines.append("")

    # ---- Wards ----
    lines.append("-- Wards (6 per hospital)")
    for w in wards:
        lines.append(
            f"INSERT INTO dbo.Wards (wardId, hospitalId, code, name, capacity) VALUES ("
            f"'{w['wardId']}', '{w['hospitalId']}', '{w['code']}', {sql_str(w['name'])}, {w['capacity']});"
        )
    lines.append("")

    # ---- Staff ----
    lines.append("-- Staff (30 per hospital)")
    today = date.today()
    staff_seq = 1000
    for h_idx, h in enumerate(ids["hospitals"], start=1):
        for role, count in ROLE_MIX:
            for _ in range(count):
                staff_seq += 1
                staff_id = f"S-{staff_seq}"
                full_name = fake.name()
                shift = SHIFTS[staff_seq % len(SHIFTS)]
                on_call = 1 if staff_seq % 7 == 0 else 0
                hire_date = today - timedelta(days=(staff_seq * 13) % 4000)
                lines.append(
                    f"INSERT INTO dbo.Staff (staffId, hospitalId, fullName, role, shift, onCall, hireDate) VALUES ("
                    f"'{staff_id}', '{h['hospitalId']}', {sql_str(full_name)}, '{role}', '{shift}', "
                    f"{on_call}, '{hire_date.isoformat()}');"
                )
        lines.append("")

    lines.append("COMMIT;")
    lines.append("")
    lines.append("-- Sanity counts")
    lines.append("SELECT 'Hospitals' AS [table], COUNT(*) AS rows FROM dbo.Hospitals")
    lines.append("UNION ALL SELECT 'Wards',     COUNT(*) FROM dbo.Wards")
    lines.append("UNION ALL SELECT 'Staff',     COUNT(*) FROM dbo.Staff;")

    out = Path(__file__).resolve().parent / "02_seed.sql"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out}  ({out.stat().st_size:,} bytes)")
    n_staff = sum(c for _, c in ROLE_MIX) * len(ids["hospitals"])
    print(f"  Hospitals: {len(ids['hospitals'])}")
    print(f"  Wards:     {len(wards)}")
    print(f"  Staff:     {n_staff}")


if __name__ == "__main__":
    main()
