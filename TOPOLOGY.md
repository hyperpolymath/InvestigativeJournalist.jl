<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# InvestigativeJournalist.jl — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │          EXTERNALS / SOURCES            │
                        ├─────────────────────────────────────────┤
                        │  ┌────────────┐      ┌────────────┐     │
                        │  │ Documents  │ ───▶ │ Web / OSINT│     │
                        │  │ (PDF/CSV)  │      │ (Ingestion)│     │
                        │  └─────┬──────┘      └─────┬──────┘     │
                        │        │                   │            │
                        └────────┼───────────────────┼────────────┘
                                 │                   │
                                 ▼                   │
                        ┌────────────────────────────┼────────────┐
                        │           APPLICATION LAYER             │
                        ├─────────────────────────────────────────┤
                        │  ┌──────────────────┐      ┌──────────┐ │
                        │  │   Ingest & Hash  │      │ Claim    │ │
                        │  │   (Provenance)   │ ───▶ │Extraction│ │
                        │  └────────┬─────────┘      └─────┬────┘ │
                        │           │                      │      │
                        │  ┌────────▼─────────┐      ┌─────▼────┐ │
                        │  │ Corroboration    │      │ Timeline │ │
                        │  │   Matrix         │ ◀──▶ │ Analysis │ │
                        │  └────────┬─────────┘      └─────┬────┘ │
                        │           │                      │      │
                        │  ┌────────▼─────────┐      ┌─────▼────┐ │
                        │  │   Intelligence   │      │ Analytics│ │
                        │  │   (Forensics)    │ ───▶ │ (Stats)  │ │
                        │  └──────────────────┘      └──────────┘ │
                        └──────────────────────┬──────────────────┘
                                               │
                        ┌──────────────────────▼──────────────────┐
                        │         REPO INFRASTRUCTURE             │
                        │  .machine_readable/ (state)             │
                        │  .github/workflows/ (RSR Gate)          │
                        │  Project.toml                           │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE WORKFLOW
  Multi-Source Ingestion            ██████████ 100%    Hashing & metadata tracking
  Claim Extraction                  ██████████ 100%    Entity linking implemented
  Corroboration Matrix              ██████████ 100%    Evidence linking & reports

INTELLIGENCE & FORENSICS
  Media Forensics                   ████████░░  80%    Image/Audio analysis basics
  Network Intelligence              ████████░░  80%    Graph-based entity analysis
  Systemic Forensics                ██████░░░░  60%    Causal pathway testing

STORYTELLING
  Story Architect                   ████████░░  80%    Templates (Longform/Thread)
  Branching Timelines               ██████████ 100%    Event & branch management
  String Board (CrazyWall)          ████████░░  80%    Visual link representation

INFRASTRUCTURE
  Secure Transfer                   ██████░░░░  60%    Drop tokens & signing
  Verisim Storage Bridge            ████████░░  80%    Registry integration
  .machine_readable/ (STATE.a2ml)   ██████████ 100%    Updated

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ████████░░  ~80%   Functional Prototype
```

## Key Dependencies

```
Ingest & Hash ──────► Claim Extraction ──────► Corroboration Matrix
                                                   │
Timeline Analysis ◀─── Network Analysis ◀──────────┘
      │
Story Architect ──────► Publication Pack ─────► COMPLETE
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
