# Coach Prep · UrbanPulse Lab

This folder is for coaches running the **UrbanPulse Data Lab**.
It contains everything you need before, during, and after the lab.

## Files

| File | Purpose |
| --- | --- |
| `pre-flight-checklist.md` | What must be true on the morning of the lab. Run through this with the lab admin 90 min before doors open. |
| `simulator-runbook.md` | How to start, stop, restart, and monitor the four streaming simulators that feed the entire lab. |

## Coach role at-a-glance

You are the **safety net**, not the lecturer. The lab is self-paced; attendees follow the HTML lab guide on their Cloud PC. You float, watch for hands raised, and pattern-match common issues:

- **"My Eventstream is empty"** → 99% of the time it's the wrong Event Hub connection string. See Module 3 in the guide.
- **"My agent gives weird answers"** → check that they pasted the *full* instructions block, including the guardrails section. Truncated instructions = hallucination.
- **"My orchestrator script errors"** → environment variables. Run `python preflight.py` to confirm.

If something is broken at the *infrastructure* level (Event Hub down, capacity throttled), escalate to the lab admin via the comms channel - don't troubleshoot it on stage.

## Schedule (per session)

| Time | Module | What attendees do | What you do |
| --- | --- | --- | --- |
| 0:00 | M0 Setup & Environment | Sign in, confirm capacity, bookmark Lab Credentials | Walk the room. Help with auth issues. |
| 0:10 | M1 Workspace Tour | Tour their pre-provisioned workspace | Highlight medallion + multi-tenancy patterns. |
| 0:40 | M2 Data Ingestion | Upload + Mirror (Azure SQL) + Mirror (Cosmos) | Most common: SQL credential typos. |
| 1:25 | M3 Streaming Ingest | Build 3 Eventstreams + 3 KQL tables | Most common: wrong Event Hub connection string. |
| 2:40 | M4 Transform | Spark notebook Silver + Gold SQL views | Most common: notebook attached to wrong Lakehouse. |
| 3:20 | M5 Live Dashboard | KQL queries + RTI Dashboard tiles | Most common: parameters not bound to data source. |
| 4:20 | M6 Direct Lake + Power BI | Semantic model + 1-page report | Most common: model needs SQL endpoint refresh. |
| 4:50 | _break_ | | |
| 5:00 | M7 Ontologies | Build the semantic graph | Most common: missing Region anchor. |
| 5:25 | M8 Fabric Data Agent | Build Hospital Operations agent | Most common: pasted only partial instructions. |
| 6:10 | M9 Multi-Agent (opt) / M10 Orchestrator (opt) | Stretch goals | Help advanced attendees connect Foundry. |
| 6:45 | Closing | Recap + Q&A | You lead a 5-minute "what did we just build" walk-through using `closing.html`. |

## Recovery scripts

If an attendee falls behind:

- **They're stuck on Module 2 mirroring** → they can skip the mirroring step and use a coach-provided `mir_urbanpulse_cityops` from the shared workspace. Modules 3+ don't depend on it.
- **They're stuck on Module 3 streaming** → drop pre-generated parquet files into the Lakehouse so they have *some* data to work with for the M4 transforms and the M5 dashboard.
- **They're stuck on Module 4 Transform** → coach-shared `silver_hospital_facility` table and Gold views are available; point them at it so they can keep moving into M5/M6.
- **They're stuck on Module 8 agent** → use the coach-shared agent endpoints (read-only). They lose the "I built this" feeling but can still complete the Apply AI track.

Goal: nobody should leave the lab without reaching the Closing recap. The "What You Built Today" table is the headline moment.
