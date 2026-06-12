# Parquet + Photo Generators

Produces the Lakehouse "Files" payload that attendees ingest in Module 2.

## Outputs

```
output/
├── facility_catalog.parquet     5 rows, 11 columns
└── facilities/
    ├── H-1.jpg
    ├── H-2.jpg
    ├── H-3.jpg
    ├── H-4.jpg
    └── H-5.jpg
```

## Run

```powershell
cd seed-data\parquet
python generate_facility_catalog.py
python generate_facility_photos.py
```

## Upload to Azure Storage

The lab assumes attendees download these from a blob container in the shared
**`rg-fabric-shared-use2-dev`** storage account. The container is named
`facilitycatalog` (this name is referenced verbatim in the M2 lab guide). After
regenerating:

```powershell
# one-time: provision the container
az storage container create --account-name <storage-acct> --name facilitycatalog --public-access blob

# upload the parquet + photos
az storage blob upload-batch `
  --account-name <storage-acct> `
  --destination facilitycatalog `
  --source seed-data\parquet\output `
  --overwrite
```

The blob URL pattern attendees see in M2 is:

```
https://<storage-acct>.blob.core.windows.net/facilitycatalog/facility_catalog.parquet
https://<storage-acct>.blob.core.windows.net/facilitycatalog/facilities/H-1.jpg
```

## Schema notes

`facility_catalog.parquet` columns:

| Column | Type | Notes |
|---|---|---|
| `facility_id` | string | Joins to SQL `Hospitals.hospitalId`. PK. |
| `facility_name` | string | |
| `facility_type` | string | Tertiary / Academic / Community / Specialty |
| `region_id` | string | Joins to Cosmos `regions.regionId`. |
| `region_name` | string | Denormalized for fast Lakehouse queries. |
| `photo_path` | string | Relative path: `facilities/<facility_id>.jpg` |
| `beds_total` | int32 | |
| `beds_icu` | int32 | |
| `accreditation` | string | |
| `opened_year` | int16 | |
| `address` | string | Synthetic, generated via Faker. |
