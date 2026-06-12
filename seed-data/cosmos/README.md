# Cosmos DB Seed (regions + trainRoutes)

Two containers used in M2 Step 3 (Cosmos shortcut) and M5/M6/M7 ontologies.

## Files

| File | Purpose |
|---|---|
| `generate_cosmos_json.py` | Materializes `regions.json` + `trainRoutes.json` from `shared/ids.json`. |
| `regions.json` | 5 region docs with boundary polygons + hospitalIds + stationIds. |
| `trainRoutes.json` | 3 route docs (Red, Blue, Green) with nested `stops`. |
| `load_cosmos.py` | Idempotent upsert via `azure-cosmos` SDK. |

## Apply

```powershell
pip install azure-cosmos

$env:COSMOS_ENDPOINT="https://<acct>.documents.azure.com:443/"
$env:COSMOS_KEY="<primary-key>"
$env:COSMOS_DATABASE="urbanpulse"   # optional; defaults to urbanpulse

python seed-data\cosmos\load_cosmos.py
```

The loader:
- Creates the database `urbanpulse` if missing.
- Creates `regions` (PK `/regionId`, 400 RU/s) if missing.
- Creates `trainRoutes` (PK `/routeId`, 400 RU/s) if missing.
- Upserts every document. Safe to re-run.

## Document shape

### `regions`
```json
{
  "id": "R-NORTH",
  "regionId": "R-NORTH",
  "name": "North District",
  "centerLat": 41.92,
  "centerLon": -87.66,
  "population": 142000,
  "hospitalIds": ["H-1"],
  "stationIds": ["ST-NRT-01", "ST-NRT-02"],
  "boundary": { "type": "Polygon", "coordinates": [[...]] }
}
```

### `trainRoutes`
```json
{
  "id": "RED",
  "routeId": "RED",
  "color": "Red",
  "trainIds": ["Train-Red-1", "Train-Red-2"],
  "stopCount": 5,
  "stops": [{ "stationId": "...", "regionId": "...", ... }],
  "regionsServed": ["R-NORTH", "R-LOOP", "R-SOUTH"]
}
```

## Regenerate after changing IDs

```powershell
python seed-data\cosmos\generate_cosmos_json.py
python seed-data\cosmos\load_cosmos.py
```
