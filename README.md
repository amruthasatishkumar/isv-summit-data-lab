# UrbanPulse · Day 2 Lab Walkthrough - Microsoft ISV Data Summit 2026

Self-contained lab guide for the **Day 2 hands-on lab** at the Microsoft ISV Data Summit (June 16–17, 2026).

> **Scenario:** UrbanPulse Analytics is an ISV building a Smart City operations platform on Microsoft Fabric. You'll build their reference architecture end-to-end across 6 modules - Lakehouse, Eventhouse, KQL Dashboard, Direct Lake, Fabric Data Agents, and a multi-agent orchestrator.

---

## Folder Structure

```
ISV Summit/
├── README.md                          ← you are here
├── lab-guide/                         ← attendee-facing HTML lab guide (open index.html)
│   ├── index.html                     ← cover page + agenda + architecture overview
│   ├── module-0-setup.html
│   ├── module-1-workspace-tour.html
│   ├── module-2-lakehouse-mirror.html
│   ├── module-3-streaming.html
│   ├── module-4-kql-dashboard.html
│   ├── module-5-data-agents.html
│   ├── module-6-direct-lake-orchestrator.html
│   ├── appendix-env-vars.html
│   ├── appendix-kql-cookbook.html
│   ├── appendix-prompt-library.html
│   └── assets/
│       ├── css/isv-summit.css         ← single source of branding
│       ├── js/print.js                ← Ctrl+P helper
│       └── images/                    ← SVG diagrams + Microsoft logo
├── coach-prep/                        ← coach-only material (NOT shared with attendees)
│   ├── README.md                      ← coach role + schedule
│   ├── pre-flight-checklist.md        ← T-90min checklist
│   └── simulator-runbook.md           ← how to run the 4 simulators
└── diagrams/                          ← editable diagram sources (Excalidraw etc.)
```

## How attendees use it

1. Cloud PC opens to `lab-guide/index.html` (or a hosted copy at `https://lab-guide.isvsummit.local`).
2. Attendees follow modules **0 → 6** sequentially. Each module is one HTML page, ~30-75 minutes.
3. Sidebar/footer nav advances them through the lab.
4. To take an offline copy: **Ctrl+P → Save as PDF** on any page.

## How to export to PDF

Per page (recommended): open the page in Edge or Chrome → **Ctrl+P** → Destination = **Save as PDF** → Layout = **Portrait** → Margins = **Default** → ✅ Background graphics → Save.

Whole guide as one PDF: open `index.html`, save as PDF, then concatenate each module PDF using any PDF merger (Edge supports drag-merge in print preview as of recent builds, or use `pdftk` / Acrobat). The print stylesheet (in `isv-summit.css` under `@media print`) handles page breaks, hides the site header, and expands `<details>` blocks automatically.

## What's included per module

| # | Module | Time | Goal |
| --- | --- | --- | --- |
| 0 | Setup & Environment Check | 15m | Verify Cloud PC, .env, preflight script |
| 1 | Workspace Tour | 20m | Tour the pre-provisioned workspace + medallion + ISV multi-tenancy |
| 2 | Lakehouse + Mirror + Shortcut | 40m | Three ingest patterns (parquet upload, Azure SQL mirror, Cosmos shortcut) |
| 3 | Streaming Ingest | 60m | 4 Eventstreams + 4 KQL tables with mappings |
| 4 | KQL + Real-Time Dashboard | 60m | KQL Queryset with 6 saved queries + RTI Dashboard with 6 tiles |
| 5 | Three Fabric Data Agents | 75m | Hospital Ops + Transit Ops + Airspace agents with custom guardrails |
| 6 | Direct Lake + Orchestrator | 45m | Semantic model + Power BI report; multi-agent orchestrator with RAG |
| A | Env Vars Cheat-Sheet | reference | Every `.env` variable explained |
| B | KQL Cookbook | reference | Reusable patterns for all 4 streaming tables |
| C | Prompt Library | reference | 30+ tested prompts by domain + difficulty |

## Branding

The lab guide uses the official ISV Data Summit purple palette layered with Microsoft Fabric teal accents and Segoe UI typography. All branding lives in **one CSS file** (`lab-guide/assets/css/isv-summit.css`) so it can be re-skinned in one place for future events.

## Source repo

Inspired by and references content from `nickTinMicrosoft/fabric_hackathon_coaches`. The Hospital Operations Agent's instructions are adapted verbatim from `Recipes/HospitalOpsAgent/04_agent_instructions.md`.

## Acknowledgements

- Microsoft Fabric team - for the platform
- @nickTin and the original hackathon coaches - for the simulator + agent recipe
- ISV Data Summit organizing committee - for the event
