# UrbanPulse · Data Lab Walkthrough

Self-contained lab guide for the **UrbanPulse Data Lab** hands-on workshop.

> **Scenario:** UrbanPulse Analytics is a software vendor building a Smart City operations platform on Microsoft Fabric. Across 11 modules organized into four goals — **Ingest, Transform, Build Report, Apply AI** — attendees build the reference architecture end-to-end: Lakehouse, Mirroring, Eventhouse, Spark notebook + SQL views, Real-Time Dashboard, Direct Lake + Power BI, Fabric Ontologies, Fabric Data Agents, and an Azure AI Foundry connected-agent orchestrator.

---

## Folder Structure

```
urbanpulse-data-lab/
├── README.md                          ← you are here
├── lab-guide/                         ← attendee-facing HTML lab guide (open index.html)
│   ├── index.html                     ← cover page + use case + 4 goal pills + 11 module cards
│   ├── module-0-setup.html
│   ├── module-1-workspace-tour.html
│   ├── module-2-lakehouse-mirror.html
│   ├── module-3-streaming.html
│   ├── module-4-transform.html
│   ├── module-5-kql-dashboard.html
│   ├── module-6-direct-lake.html
│   ├── module-7-ontologies.html
│   ├── module-8-data-agents.html
│   ├── module-9-multi-agent.html
│   ├── module-10-foundry-orchestrator.html
│   ├── closing.html                   ← multi-tenant pattern picture + final recap
│   ├── appendix-env-vars.html         ← Lab Credentials
│   ├── appendix-data-downloads.html   ← Lab Data Downloads
│   ├── appendix-prompt-library.html
│   └── assets/
│       ├── css/data-lab.css           ← single source of branding
│       ├── js/print.js                ← sidebar nav + Ctrl+P helper
│       ├── downloads/                 ← parquet + facility photos for M2 Option B
│       └── images/                    ← SVG diagrams + Microsoft logo
├── coach-prep/                        ← coach-only material (NOT shared with attendees)
│   ├── README.md                      ← coach role + schedule
│   ├── pre-flight-checklist.md        ← T-90min checklist
│   └── simulator-runbook.md           ← how to run the 3 simulators
└── diagrams/                          ← editable diagram sources (Excalidraw etc.)
```

## How attendees use it

1. Lab machine opens to `lab-guide/index.html`.
2. Attendees follow modules **0 → 10** sequentially, then `closing.html`. Each module is one HTML page, ~20–75 minutes.
3. The sticky sidebar groups modules under each goal so attendees can jump to a phase. The Goals page also has filter pills (All · Ingest · Transform · Build Report · Apply AI).
4. To take an offline copy: **Ctrl+P → Save as PDF** on any page.

## How to export to PDF

Per page (recommended): open the page in Edge or Chrome → **Ctrl+P** → Destination = **Save as PDF** → Layout = **Portrait** → Margins = **Default** → ✅ Background graphics → Save.

Whole guide as one PDF: open `index.html`, save as PDF, then concatenate each module PDF using any PDF merger (Edge supports drag-merge in print preview as of recent builds, or use `pdftk` / Acrobat). The print stylesheet (in `data-lab.css` under `@media print`) handles page breaks, hides the site header, and expands `<details>` blocks automatically.

## What's included per module

| # | Module | Time | Goal |
| --- | --- | --- | --- |
| 0 | Setup & Environment Check | 10m | Sign in, confirm capacity, bookmark Lab Credentials |
| 1 | Workspace Tour & Solution Architecture | 30m | Tour the pre-provisioned workspace + medallion + multi-tenancy |
| 2 | Data Ingestion | 45m | G1 · Three ingest patterns (Parquet upload, Azure SQL mirror, Cosmos mirror) |
| 3 | Real-Time Streaming Ingest | 75m | G1 · 3 Eventstreams + 3 KQL tables fed from Event Hubs |
| 4 | Transform for Analytics | 40m | G2 · Spark notebook for Silver Delta + SQL views for Gold |
| 5 | Live Dashboard | 60m | G3 · KQL queries + Real-Time Intelligence Dashboard |
| 6 | Direct Lake + Power BI | 30m | G3 · Semantic model and 1-page Power BI report |
| 7 | Fabric Ontologies | 25m | G4 · Semantic graph over Lakehouse + Eventhouse data |
| 8 | Fabric Data Agent | 45m | G4 · Hospital Operations agent grounded on KQL |
| 9 | Multi-Agent Catalog *(Optional)* | 20m | G4 · Add Transit Ops agent for a two-domain catalog |
| 10 | Foundry Orchestrator *(Optional)* | 30m | G4 · Azure AI Foundry connected-agent orchestrator |
| End | Closing | — | Multi-tenant pattern picture + recap of everything you built |
| A | Lab Credentials | reference | Per-user lab accounts and Azure resource locations |
| B | Lab Data Downloads | reference | Facility catalog parquet + photos for M2 Option B |
| C | Prompt Library | reference | Hospital + Transit + Orchestrator prompts by difficulty |

## Branding

The lab guide uses a purple palette layered with Microsoft Fabric teal accents and Segoe UI typography. All branding lives in **one CSS file** (`lab-guide/assets/css/data-lab.css`) so it can be re-skinned in one place for future events.

## Source repo

Inspired by and references content from `nickTinMicrosoft/fabric_hackathon_coaches` and `nickTinMicrosoft/fabric_hackathon_attendee` (Goal 2 — Transform). The Hospital Operations Agent's instructions are adapted from `Recipes/HospitalOpsAgent/04_agent_instructions.md`.

## Acknowledgements

- Microsoft Fabric team - for the platform
- @nickTin and the original hackathon coaches - for the simulator + agent recipe
