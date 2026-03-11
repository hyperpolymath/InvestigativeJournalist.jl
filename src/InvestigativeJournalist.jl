# SPDX-License-Identifier: PMPL-1.0-or-later
"""
    InvestigativeJournalist

Investigative journalism toolkit for OSINT, data analysis, source management, and
storytelling. Covers the full investigative pipeline from document ingestion and
claim extraction through network intelligence, media forensics, and publication.

# Key Features
- Source document ingestion, claim extraction, and evidence linking
- Network intelligence graphs and "crazy wall" string boards
- Media forensics (image integrity, AI artifact detection, audio enhancement)
- Secure evidence transfer with cryptographic signing
- Story templates (longform, news bulletin, thread) and branching timelines

# Example
```julia
using InvestigativeJournalist
doc = ingest_source("leaked_report.pdf")
claims = extract_claim(doc)
report = corroboration_report(claims)
```
"""
module InvestigativeJournalist

include("types.jl")
include("ingest.jl")
include("claims.jl")
include("corroboration.jl")
include("parsers.jl")
include("shield/unlock.jl")
include("audio/production.jl")
include("shield/secure_transfer.jl")
include("intelligence/network.jl")
include("intelligence/forensics.jl")
include("interop/bridge.jl")
include("storytelling/templates.jl")
include("analytics/statistics.jl")
include("storytelling/timelines.jl")
include("intelligence/string_board.jl")
include("intelligence/systemic.jl")
include("intelligence/media_pro.jl")
include("storage/verisim_bridge.jl")

using .Types
using .Ingest
using .Claims
using .Corroboration
using .Parsers
using .DocumentUnlock
using .AudioProduction
using .SecureTransfer
using .NetworkIntelligence
using .MediaForensics
using .InteropBridge
using .StoryArchitect
using .InvestigativeAnalytics
using .BranchingTimelines
using .StringBoard
using .SystemicForensics
using .MediaPro
using .VeriSimBridge

# Re-export operations
export SourceDoc, Claim, EvidenceLink, Entity, Event, FOIARequest, StoryDraft
export ingest_source, extract_claim, link_evidence, corroboration_report
export parse_contract, parse_job_description, compare_policies
export unlock_pdf, force_extract_text
export PodcastScript, add_segment!, generate_show_notes
export generate_drop_token, sign_evidence_pack
export InvestigativeGraph, add_connection!, find_shortest_path
export verify_image_integrity, detect_ai_artifacts
export run_r_script, export_to_stata, export_to_spss
export StoryTemplate, Longform, NewsBulletin, Thread, build_story_structure
export benfords_law_check, find_outliers
export TimelineBranch, TimelineEvent, add_event!, create_branch
export CrazyWall, add_photo!, add_string!
export model_instability_context, test_causal_pathway, assess_black_swan
export isolate_signal, denoise_audio, enhance_clarity
export register_investigation_hexad, vql_query

end # module InvestigativeJournalist
