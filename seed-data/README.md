# UrbanPulse Seed Data

Reproducible seed data for the ISV Summit UrbanPulse lab.
Everything here is **deterministic, synthetic, PII-free** and is regenerated
from these scripts on demand — nothing in this folder is the source of truth
for real-world data.

```
seed-data/
├── parquet/    Facility catalog (Parquet) + facility photo cards (JPG)
├── sql/        Azure SQL DDL + seed for Hospitals / Wards / Staff
├── cosmos/     Cosmos DB JSON for regions + trainRoutes
├── eventhub/   Live event simulators for medicalvitals / medicalmovement / metrotrain
└── shared/     Common ID lookups (used by simulators to ensure FK validity)
```

## The data model at a glance

| Layer | Asset | Cardinality | Joins to |
|---|---|---|---|
| Parquet (Storage → Lakehouse Files) | `facility_catalog.parquet` + `facilities/<facility_id>.jpg` | 5 facilities | SQL `Hospitals.hospitalId` |
| Azure SQL (mirrored) | `Hospitals`, `Wards`, `Staff` | 5 / 30 / 150 | streams + Cosmos regions |
| Cosmos DB (shortcut) | `regions`, `trainRoutes` | 5 / 3 | SQL hospitals + train telemetry |
| Event Hubs | `medicalvitals`, `medicalmovement`, `metrotrain` | live | facilities + wards + train routes |

The IDs (`H-1..H-5`, `W-1..W-30`, `R-NORTH..R-SOUTH`, `Train-Red-1` etc.) are
shared across every layer so cross-domain queries in M2/M5/M6/M7/M9 produce
real joins instead of orphaned rows.

## Usage (typical coach pre-flight)

1. **Regenerate batch artifacts** (idempotent, ~5 seconds):
   ```powershell
   cd seed-data\parquet; python generate_facility_catalog.py
   cd ..\parquet; python generate_facility_photos.py
   ```
2. Upload `seed-data/parquet/output/` to the `facilitycatalog` container in your
   Azure Storage account (lab attendees download from there in M2 Step 3 - see
   `seed-data/parquet/README.md` for the `az storage blob upload-batch` command).
3. Apply SQL schema + seed against your lab Azure SQL DB:
   ```powershell
   sqlcmd -S <server>.database.windows.net -d <db> -G -i seed-data\sql\01_schema.sql
   sqlcmd -S <server>.database.windows.net -d <db> -G -i seed-data\sql\02_seed.sql
   ```
4. Load Cosmos JSON:
   ```powershell
   $env:COSMOS_ENDPOINT='https://<acct>.documents.azure.com:443/'
   $env:COSMOS_KEY='<primary-key>'
   python seed-data\cosmos\load_cosmos.py
   ```
5. Start streaming simulators (background, run once per event):
   ```powershell
   $env:EVENTHUB_VITALS_CONN_STR='...';   python seed-data\eventhub\simulate_medicalvitals.py
   $env:EVENTHUB_MOVEMENT_CONN_STR='...'; python seed-data\eventhub\simulate_medicalmovement.py
   $env:EVENTHUB_TRAIN_CONN_STR='...';    python seed-data\eventhub\simulate_metrotrain.py
   ```

## Conventions

- **No PII.** All names are `Faker.seed(42)` — deterministic, fictional.
- **No real medical data.** Vitals are randomized within plausible ranges.
- **Region polygons** are 4-vertex squares around fictional `Metropolis` lat/lon —
  not real geography.
- **Times** are UTC ISO-8601 with millisecond precision.
- All scripts read shared IDs from `seed-data/shared/ids.json` so updating
  cardinality is a single-file change.
