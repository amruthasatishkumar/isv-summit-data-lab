# Pre-Flight Checklist · 90 Minutes Before Doors Open

Run through this with the lab admin **90 minutes** before each session. Everything must be ✅ before attendees arrive.

> **Owner:** Lab admin runs steps 1–6 (capacity, ingest, secrets). Lead coach runs steps 7–10 (sample-content + recovery).

---

## 1. Fabric capacity is up and not throttling
- [ ] Open Fabric admin portal → Capacities → `cap-isvsummit-2026`
- [ ] Status is **Active**, SKU is **F32 or larger**
- [ ] CU usage in last 1 hour is **< 60%** (no leftover background jobs)

## 2. Per-attendee workspaces are provisioned
- [ ] One workspace per registered attendee, named `urbanpulse-{userId}`
- [ ] Each workspace is bound to `cap-isvsummit-2026`
- [ ] The lab service account is owner of each workspace
- [ ] Each attendee's account is a **Member** (not Admin) of their workspace

## 3. Event Hubs are receiving data from the simulators
- [ ] `evhns-isvsummit-2026` namespace is healthy
- [ ] All four hubs receiving messages in the last 60 seconds:
  - [ ] `eh-hospital-vitals` - 15 patients, ~8s cadence
  - [ ] `eh-hospital-movement` - sporadic
  - [ ] `eh-metra-trains` - 3 trains, ~3s cadence
  - [ ] `eh-flight-tracker` - variable depending on PiAware feed

> **How to check:** Azure portal → Event Hubs Namespace → Metrics → `Incoming Messages (Last 5 min)` filtered by Entity name.

## 4. Source databases healthy
- [ ] Azure SQL `sql-isvsummit.database.windows.net / studentdb` is online
- [ ] `lab_reader` user can SELECT from `Students`, `Classes`, `Enrollments`
- [ ] Cosmos DB `cosmos-isvsummit / StudentInfo / Grades` has at least 5,000 documents
- [ ] Tumor parquet file is in the lab admin's blob storage and accessible via SAS URL

## 5. Azure AI services are warm
- [ ] Azure AI Search index `city-ops-index` exists and has > 0 documents
- [ ] Azure OpenAI deployment `gpt-4o-mini` exists and capacity ≥ 30 K TPM
- [ ] A test call to AOAI succeeds in < 3 seconds

## 6. Per-attendee `.env` files are placed
- [ ] Each Cloud PC has `.env` at `C:\labs\fabric_hackathon_coaches\.env`
- [ ] File is owned by lab-admin, group-read-only for the attendee
- [ ] The "Update env" desktop shortcut exists (script that re-writes if values rotate)

## 7. Attendee preflight script runs clean
On a randomly chosen Cloud PC, log in as a fresh attendee account and run:

```powershell
cd C:\labs\fabric_hackathon_coaches
python Scripts\Python\preflight.py
```

Expected output ends with:

```
✓ All 4 Event Hubs reachable
✓ Azure SQL reachable
✓ Cosmos DB reachable
✓ Azure AI Search reachable
✓ Azure OpenAI reachable
✓ Fabric workspace 'urbanpulse-u01' visible
PRE-FLIGHT PASSED
```

If any line is ✗, do **not** proceed - fix and re-run.

## 8. Sample content is staged
- [ ] Tumor parquet file is downloadable via the `Day 2 Files` SharePoint link from the lab guide
- [ ] Kqlsetup recipe (`02_kql_tables.kql`) is current
- [ ] Pre-built agent endpoints (the coach-shared fallback) are responsive

## 9. Recovery datasets are ready
- [ ] `recover/hospital-snapshot.parquet` - 24 hours of vitals (in case streaming fails mid-lab)
- [ ] `recover/trains-snapshot.parquet` - 24 hours
- [ ] `recover/flights-snapshot.parquet` - 24 hours
- [ ] Each snapshot has a `Load to KQL` recipe nearby in case you need to reroute attendees

## 10. Coach roster + Cloud PC mapping
- [ ] Each coach knows which 8–12 attendees they're responsible for
- [ ] You have a printed cheat-sheet with `userId → cloudPcName → workspaceName` mapping
- [ ] Slack/Teams channel for coach-to-admin escalation is open and tested

---

## At T-15 minutes
- [ ] Re-run the simulator runbook validation (see `simulator-runbook.md`)
- [ ] Confirm the lab guide is reachable from each Cloud PC at `https://lab-guide.isvsummit.local`
- [ ] Print 5 emergency reset cards (with credentials) in case someone's PC is in a bad state

## At T-0
- [ ] Lead coach makes opening announcement (5 min)
- [ ] Attendees go to **Module 0** of the lab guide

## After the session
- [ ] Drain Event Hubs back to baseline
- [ ] Reset each workspace to a clean state via the `reset-workspace.ps1` script
- [ ] Capture any pain-point notes in the post-mortem doc
