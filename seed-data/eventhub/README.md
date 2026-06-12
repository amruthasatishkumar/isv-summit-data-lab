# Event Hub Simulators

Three simulators that drive the M3 streaming demo against the real
**`rtidemo`** Event Hubs namespace in `rg-fabric-shared-use2-dev`:

| Simulator | Hub | KQL table | Frequency |
|---|---|---|---|
| `simulate_medicalvitals.py` | `medicalvitals` | `HospitalVitals` | ~3 events/sec |
| `simulate_medicalmovement.py` | `medicalmovement` | `HospitalMovement` | ~1 event / 5 sec |
| `simulate_metrotrain.py` | `metrotrain` | `TrainTelemetry` | 6 events / 2 sec (one per train) |

## Schema authority

All three JSON payload shapes are **locked to** the `.create table` and
`ingestion json mapping` definitions in [module-3-streaming.html](../../lab-guide/module-3-streaming.html).
Do not rename payload fields — the M3 KQL ingestion mapping uses
`$.<field>` JSONPath and will silently drop any non-matching property.

Fields prefixed with `_` (e.g. `_hospitalId`, `_wardId`) are intentionally
not in the KQL schema; they're carried through as auxiliary application
properties for downstream debugging and Eventstream routing experiments.

## Setup

```powershell
pip install azure-eventhub
```

## Connection strings

Generate from the Azure portal under **Event Hubs namespace `rtidemo` →
Shared access policies → RootManageSharedAccessKey**, then per-hub
**Connection string – primary key** for each hub. The string MUST end with
`;EntityPath=<hubName>`.

```powershell
$env:EVENTHUB_VITALS_CONN_STR   = "Endpoint=sb://rtidemo.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=...;EntityPath=medicalvitals"
$env:EVENTHUB_MOVEMENT_CONN_STR = "Endpoint=sb://rtidemo.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=...;EntityPath=medicalmovement"
$env:EVENTHUB_TRAIN_CONN_STR    = "Endpoint=sb://rtidemo.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=...;EntityPath=metrotrain"
```

## Run

In three separate terminals (the lab needs all three flowing):

```powershell
python seed-data\eventhub\simulate_medicalvitals.py
python seed-data\eventhub\simulate_medicalmovement.py
python seed-data\eventhub\simulate_metrotrain.py
```

## Tuning

Each simulator honors:

| Var | Default | Effect |
|---|---|---|
| `SIM_DURATION_SECONDS` | 600 | How long to keep producing |
| `SIM_INTERVAL_SECONDS` | 1.0 / 5.0 / 2.0 | Tick interval |

For a coach pre-flight burst that just primes the KQL tables:

```powershell
$env:SIM_DURATION_SECONDS=30
python seed-data\eventhub\simulate_medicalvitals.py
```

## Stopping

Each script handles `Ctrl+C` cleanly and prints the final event count.
