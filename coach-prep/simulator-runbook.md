# Simulator Runbook

The three streaming simulators are the heartbeat of the lab. If they stop, **every module from M3 onward goes dark**. This doc tells you how to start, monitor, restart, and tune them.

> **Source:** all simulators live in this repo at `seed-data/eventhub/`.

---

## The Three Simulators

| Simulator | Script | Cadence | Volume |
| --- | --- | --- | --- |
| Hospital vitals | `seed-data/eventhub/simulate_medicalvitals.py` | every 1 sec, 2-5 events per tick | ~12,000 events/hr |
| Hospital movement | `seed-data/eventhub/simulate_medicalmovement.py` | every 5 sec, 1-3 events per tick | ~1,400 events/hr |
| Metra trains | `seed-data/eventhub/simulate_metrotrain.py` | every 2 sec, one event per train (6 trains) | ~10,800 events/hr |

All three publish JSON to the **`rtidemo`** Event Hubs namespace
(in resource group `rg-fabric-shared-use2-dev`).

---

## Hosting

Simulators run on **`vm-simulator-isvsummit`** - a single Windows Server VM in the lab admin subscription. Reasons:

- One place to start/stop everything
- Centralizes cost: simulators publish *once*, all attendees consume the same Event Hub data

> Attendees do **not** run the simulators themselves. They consume already-flowing Event Hub data via Eventstream in Module 3.

---

## Starting Simulators

Set the three connection strings (once per session) and run all three in
separate PowerShell windows.

```powershell
$env:EVENTHUB_VITALS_CONN_STR   = "Endpoint=sb://rtidemo.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=...;EntityPath=medicalvitals"
$env:EVENTHUB_MOVEMENT_CONN_STR = "Endpoint=sb://rtidemo.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=...;EntityPath=medicalmovement"
$env:EVENTHUB_TRAIN_CONN_STR    = "Endpoint=sb://rtidemo.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=...;EntityPath=metrotrain"

# Window 1
cd C:\sim\isv-summit-data-lab
python seed-data\eventhub\simulate_medicalvitals.py

# Window 2
python seed-data\eventhub\simulate_medicalmovement.py

# Window 3
python seed-data\eventhub\simulate_metrotrain.py
```

Each simulator's default duration is 600 seconds (10 minutes); override with
`$env:SIM_DURATION_SECONDS=10800` for a 3-hour lab session.

---

## Validating Each Simulator

Each simulator prints a final event count when it stops:

```
Sent 6428 events.
```

For a continuous health check, run the M3 validation KQL in a Fabric KQL queryset:

```kql
union withsource = table
    HospitalVitals, HospitalMovement, TrainTelemetry
| where timestamp > ago(2m)
| summarize events = count() by table
```

In a healthy lab, all three tables show non-zero counts within 30 seconds of
the simulators starting.

---

## Common Issues

### Issue: One hub shows zero events but the script reports "Sent N events"

99% of the time this is a connection-string EntityPath mismatch. Confirm the
connection string ends with the correct `EntityPath=...` for that hub:

| Env var | Required EntityPath |
|---|---|
| `EVENTHUB_VITALS_CONN_STR` | `EntityPath=medicalvitals` |
| `EVENTHUB_MOVEMENT_CONN_STR` | `EntityPath=medicalmovement` |
| `EVENTHUB_TRAIN_CONN_STR` | `EntityPath=metrotrain` |

### Issue: Patient IDs jumped after a simulator restart

The vitals + movement simulators rotate through deterministic patient IDs
`P-1-001` through `P-5-012` (5 hospitals * 12 patients). Restarts re-emit the
same IDs - that's fine. The KQL `arg_max` patterns absorb duplicates.

### Issue: Train script is sending data but TrainTelemetry KQL table is empty

Either the JSON ingestion mapping name doesn't match `TrainTelemetry_mapping`,
or the Eventstream destination isn't pointed at the `TrainTelemetry` table.
Confirm both via the M3 lab guide validation steps. Mismatched name = silent drops.

### Issue: Lab is over and Event Hubs cost is climbing

Hit `Ctrl+C` in each of the three simulator windows. The 1-hour retention on
the hubs means the data ages out automatically - no manual drain needed.
Don't delete the namespace; you'll need it for the next session.

---

## Tuning (rarely needed)

### Raising vitals cadence for demos

Override the env var when launching:

```powershell
$env:SIM_INTERVAL_SECONDS=0.5
python seed-data\eventhub\simulate_medicalvitals.py
```

Don't go below 0.25 seconds - Event Hub throughput throttles will engage at
the 1 TU default.

### Forcing a critical-condition spike

The vitals simulator already injects a ~7% spike rate (heart rate >140,
SpO2 <90, fever) which keeps M3's "critical patients" KQL query alive
without operator intervention. To deliberately spike for a demo, edit
`simulate_medicalvitals.py` and bump the `random.random() < 0.07` literal.

### Forcing train delays

The train simulator already injects a ~1.5% fault rate (status `fault`,
slowed speed) on in-transit ticks. To deliberately stall a train, edit
`simulate_metrotrain.py` and bump the `random.random() < 0.015` literal.

---

## Restart Recipe (if everything is wedged)

```powershell
# 1. Stop all simulators (Ctrl+C in each window)

# 2. Wait 30 seconds for Event Hub to flush
Start-Sleep -Seconds 30

# 3. Re-pull the latest scripts (in case of mid-event hotfix)
cd C:\sim\isv-summit-data-lab
git pull

# 4. Restart all three simulators (see "Starting Simulators" above)

# 5. Validate end-to-end (run the union KQL above)
```

If the validation KQL still shows zero rows after this, the issue is
downstream of the simulators (Event Hub - Eventstream - KQL). Check the
Eventstream tile in the lab admin's reference workspace to confirm.
