# Simulator Runbook

The four streaming simulators are the heartbeat of the lab. If they stop, **every module from M3 onward goes dark**. This doc tells you how to start, monitor, restart, and tune them.

> **Source:** all simulators live in `nickTinMicrosoft/fabric_hackathon_coaches → Scripts/Python/`.

---

## The Four Simulators

| Simulator | Script | Cadence | Volume |
| --- | --- | --- | --- |
| Hospital vitals | `Scripts/Python/Hospital/hospital_vitals.py` | every 8 sec | 15 patients × 8s = ~6,750 events/hr |
| Hospital movement | `Scripts/Python/Hospital/hospital_movement.py` | sporadic | ~50 events/hr |
| Metra trains | `Scripts/Python/Trains/trains_eventhub.py` | every 3 sec | 3 trains × 3s = ~3,600 events/hr |
| Flight tracker | `Scripts/Python/Flight/flight_tracker.py` | event-driven | depends on PiAware feed; typically 200-2,000 events/hr |

All four publish JSON to Azure Event Hubs.

---

## Hosting

Simulators run on **`vm-simulator-isvsummit`** - a single Windows Server 2022 VM in the lab admin subscription. Reasons:

- One place to start/stop everything
- A single PiAware ADS-B receiver (the flight script) can't be fan-out across attendees
- Centralizes cost: simulators publish *once*, all attendees consume the same Event Hub data

> Attendees do **not** run the simulators themselves. They consume already-flowing Event Hub data via Eventstream in Module 3.

---

## Starting Simulators

On `vm-simulator-isvsummit`, in 4 separate PowerShell windows:

```powershell
# Window 1
cd C:\sim\fabric_hackathon_coaches
python Scripts\Python\Hospital\hospital_vitals.py

# Window 2
python Scripts\Python\Hospital\hospital_movement.py

# Window 3
python Scripts\Python\Trains\trains_eventhub.py

# Window 4
python Scripts\Python\Flight\flight_tracker.py
```

Or use the wrapper:

```powershell
C:\sim\start-all.ps1
```

This script launches each simulator as a Windows service-like background job and routes logs to `C:\sim\logs\`.

---

## Validating Each Simulator

Each simulator prints a heartbeat every 30 seconds:

```
[hospital_vitals] sent 45 events in last 30s · ok
[hospital_movement] sent 1 event in last 30s · ok
[trains_eventhub] sent 30 events in last 30s · ok
[flight_tracker] sent 12 events in last 30s · ok (PiAware connected)
```

If a heartbeat says `last seen > 60s ago`, the simulator is wedged. Restart that one window.

To validate **end to end** (Event Hub → Eventstream → KQL), use the validation KQL from the lab guide:

```kql
union withsource = table
    HospitalVitals, HospitalMovement, TrainTelemetry, FlightTelemetry
| where timestamp > ago(2m)
| summarize events = count() by table
```

In a healthy lab, all four tables show non-zero counts.

---

## Common Issues

### Issue: Hospital simulator restarted, patient IDs jumped

The hospital simulator generates patient IDs `PAT-10001` through `PAT-10015` deterministically. Restarts re-emit the same IDs - that's fine. The KQL `arg_max` patterns absorb duplicates.

### Issue: Flight tracker log says "PiAware not connected"

The PiAware receiver is on `pi-flighttracker.lab.local`. Common causes:
- Receiver lost power → physically check the device on the AV cart
- Network issue → ping the device, restart its switch port if needed
- Device firmware froze → unplug/replug, wait 60 sec, restart `flight_tracker.py`

If PiAware is down, the lab continues with empty `FlightTelemetry`. That's fine for M3-M4 (just less colorful) but **breaks the Airspace agent in M5**. Switch attendees to the recover dataset:

```powershell
# On the lab admin VM
python Scripts\Python\recover\replay_flights.py --speed 1.0
```

This replays a 24-hour snapshot at real-time speed into `eh-flight-tracker`. Attendees see no difference.

### Issue: Train script is sending data but TrainTelemetry KQL table is empty

The KQL table mapping name doesn't match. From the script:

```python
producer.send_event(
    EventData(json.dumps(payload)),
    properties={"DataMappingName": "TrainTelemetry_mapping"}
)
```

Confirm the JSON ingestion mapping is named exactly `TrainTelemetry_mapping`. Mismatched name = silent drops.

### Issue: Lab is over and Event Hubs cost is climbing

Stop all four simulators. Optionally drain Event Hubs by reducing retention to 1 day. Don't delete the namespace - you'll need it for the next session.

```powershell
C:\sim\stop-all.ps1
```

---

## Tuning (rarely needed)

### Raising hospital cadence for demos
Edit `hospital_vitals.py`:

```python
CADENCE_SECONDS = 8   # default
# CADENCE_SECONDS = 2 # for "exciting demo" mode
```

Don't go below 2 seconds - Event Hub throughput throttles will engage.

### Forcing a critical-condition spike
The hospital script has a `--scenario critical_spike` flag:

```powershell
python hospital_vitals.py --scenario critical_spike
```

This forces 4 patients into critical condition for 5 minutes. Use only when demoing the orchestrator's "Region A spike" prompt.

### Forcing train delays
The train script has a similar `--scenario green_delay` flag that pins Train-Green-1 to `Delayed` status for the next 10 minutes.

---

## Restart Recipe (if everything is wedged)

```powershell
# 1. Stop all simulators
C:\sim\stop-all.ps1

# 2. Wait 30 seconds for Event Hub to drain
Start-Sleep -Seconds 30

# 3. Re-pull the latest scripts (in case of mid-event hotfix)
cd C:\sim\fabric_hackathon_coaches
git pull

# 4. Restart everything
C:\sim\start-all.ps1

# 5. Validate end-to-end (run the union KQL above)
```

If the validation KQL still shows zero rows after this, the issue is downstream of the simulators (Event Hub → Eventstream → KQL). Check the Eventstream tile in the lab admin's reference workspace to confirm.
