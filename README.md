<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2025-2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

[![Topology](https://img.shields.io/badge/Project-Topology-9558B2)](TOPOLOGY.md)
[![80](https://img.shields.io/badge/Completion-80%25-green)](TOPOLOGY.md) [![OpenSSF Best Practices](https://img.shields.io/badge/OpenSSF-Best_Practices-green?logo=opensourcesecurity)](https://www.bestpractices.dev/en/projects/new?repo_url=https://github.com/hyperpolymath/InvestigativeJournalist.jl)
[![License: PMPL-1.0](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://github.com/hyperpolymath/palimpsest-license) <embed
src="https://api.thegreenwebfoundation.org/greencheckimage/github.com"
data-link="https://www.thegreenwebfoundation.org/green-web-check/?url=github.com" />
image:<a href="https://img.shields.io/badge/Julia-1.10+-9558B2?logo=julia"
data-link="https://julialang.org/">Julia</a>

**Structured Evidence for High-Stakes Reporting**

*Turn messy source material into audit-ready investigative artifacts.*

<div id="toc">

</div>

# Overview

InvestigativeJournalist.jl is a Julia toolkit for managing the
end-to-end investigative reporting workflow. It provides high-integrity
structures for ingesting diverse sources, extracting verifiable claims,
and building a corroboration matrix that minimizes editorial and legal
risk.

# Core Capabilities

- **Multi-Source Ingestion**: Ingest documents, web snapshots, and
  interview notes with automatic hashing and deduplication.

- **Claim Extraction**: Extract discrete claims and link them to
  entities (people, orgs, places).

- **Corroboration Matrix**: Quantify confidence levels across claims and
  multiple supporting sources.

- **Auditable Provenance**: Every claim in your final draft traces back
  to a cryptographically hashed source document.

- **Timeline & Network Analysis**: Visualize actors and events to detect
  gaps or contradictions in narratives.

# Quick Start

```julia
using InvestigativeJournalist

# Ingest a source document
doc = ingest_source("docs/leaked_contract.pdf")

# Extract claims and link to entities
claims = extract_claims(doc)
link_entities!(claims)

# Build a corroboration matrix
matrix = corroborate(claims, all_docs())

# Generate a publication-ready evidence pack
pack = generate_publication_pack(story_draft)
```

# Suggested Tech Stack

- **Data**: `DataFrames.jl`, `Arrow.jl`, `JSON3.jl`

- **Persistence**: `SQLite.jl` or `DuckDB.jl`

- **Text Analysis**: `TextAnalysis.jl`

- **Visualization**: `Makie.jl`

# Safety & Governance

- **Source Protection**: Support for encrypted fields and redacted
  exports for sensitive whistleblowers.

- **Audit Trail**: Immutable logs for every change in confidence scores
  or claim text.

- **Zero-Unreferenced Policy**: Final publication packages prevent
  inclusion of any claim without a verified evidence link.

# License

Palimpsest-MPL-1.0 License - see [LICENSE](LICENSE) for details.
