# Azure SQL Schema + Seed

Creates the **Hospitals / Wards / Staff** tables that get mirrored into
Fabric in Module 2 and queried by ontologies in Module 6.

## Files

| File | Purpose |
|---|---|
| `01_schema.sql` | DDL — drops + recreates the 3 tables. Also drops legacy edu tables (`Students`/`Classes`/`Enrollments`) if present. |
| `02_seed.sql` | Generated INSERT statements (5 hospitals, 30 wards, 150 staff). **Do not edit by hand** — regenerate via the script below. |
| `generate_seed_sql.py` | Re-emits `02_seed.sql` from `seed-data/shared/ids.json`. |

## Apply to Azure SQL DB

```powershell
$server = "<server>.database.windows.net"
$db     = "<database>"

sqlcmd -S $server -d $db -G -i seed-data\sql\01_schema.sql
sqlcmd -S $server -d $db -G -i seed-data\sql\02_seed.sql
```

`-G` uses Azure AD auth; swap for `-U`/`-P` for SQL auth.

You can also paste both files into the Azure portal's **Query editor**
on the SQL Database blade.

## Regenerate after changing IDs

```powershell
python seed-data\sql\generate_seed_sql.py
```

## Schema overview

```
Hospitals (PK hospitalId)
   ├── Wards (FK hospitalId)
   └── Staff (FK hospitalId)
```

| Table | Rows | Notes |
|---|---|---|
| `Hospitals` | 5 | One per region. `regionId` joins to Cosmos `regions` shortcut. |
| `Wards`     | 30 | 6 ward types × 5 hospitals. `wardId` referenced by event hub `medicalvitals` payloads. |
| `Staff`     | 150 | Mix per hospital: 8 nurse / 6 physician / 4 tech / 4 EMS / 4 admin / 4 housekeeping. |
