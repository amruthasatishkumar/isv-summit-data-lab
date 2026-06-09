# Coach Prep · UrbanPulse Lab

This folder is for coaches running the **Day 2 Lab** at the Microsoft ISV Data Summit.
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
| 0:00 | M0 Setup | Verify Cloud PC, run preflight | Walk the room. Help with auth issues. |
| 0:15 | M1 Workspace | Tour their pre-provisioned workspace | Highlight medallion + multi-tenancy patterns. |
| 0:35 | M2 Lakehouse | Upload + Mirror + Shortcut | Most common: SQL credential typos. |
| 1:15 | M3 Streaming | Build 4 Eventstreams + KQL tables | Most common: wrong conn-str. |
| 2:15 | M4 KQL Dashboard | Build 6 tiles + RTI Dashboard | Most common: forgot to set semantic model permissions. |
| 3:15 | _break_ | | |
| 3:30 | M5 Agents | Build 3 Fabric Data Agents | Most common: pasted only partial instructions. |
| 4:45 | M6 Direct Lake + Orchestrator | Final ISV pattern | Most common: agent endpoints not yet stable. |
| 5:30 | Recap | Q&A | You lead a 5-minute "what did we just build" walk-through. |

## Recovery scripts

If an attendee falls behind:

- **They're stuck on Module 2 mirroring** → they can skip the mirroring step and use a coach-provided `mir_urbanpulse_studentdb` from the shared workspace. Modules 3+ don't depend on it.
- **They're stuck on Module 3 streaming** → use the `recover/` folder of the simulator repo to drop pre-generated parquet files into the Lakehouse so they have *some* data to work with for KQL queries in M4.
- **They're stuck on Module 5 agents** → use the coach-shared agent endpoints (read-only). They lose the "I built this" feeling but can still complete M6.

Goal: nobody should leave the lab without seeing the orchestrator output at the end. That's the headline moment.
