# SPDX-License-Identifier: PMPL-1.0-or-later
module Types

using Dates

export SourceDoc, Claim, EvidenceLink, Entity, Event, FOIARequest, StoryDraft

struct SourceDoc
    id::Symbol
    source_type::Symbol # :document, :web, :interview, :leak
    title::String
    path_or_url::String
    collected_at::DateTime
    hash::String # SHA-256 for provenance
end

struct Claim
    id::Symbol
    text::String
    topic::String
    extracted_from_doc::Symbol
    created_at::DateTime
end

struct EvidenceLink
    claim_id::Symbol
    source_doc_id::Symbol
    support_type::Symbol # :supports, :contradicts, :nuances
    confidence::Float64  # 0.0 to 1.0
    notes::String
end

struct Entity
    id::Symbol
    kind::Symbol # :person, :organization, :place
    canonical_name::String
    aliases::Vector{String}
end

struct Event
    id::Symbol
    occurred_at::DateTime
    location::String
    summary::String
    linked_entities::Vector{Symbol}
end

mutable struct FOIARequest
    id::Symbol
    agency::String
    submitted_at::DateTime
    status::Symbol # :pending, :responded, :appealed, :denied
    due_at::DateTime
    docs_received::Vector{Symbol} # SourceDoc IDs
end

mutable struct StoryDraft
    id::Symbol
    headline::String
    narrative_blocks::Vector{String}
    legal_flags::Vector{String}
    is_vetted::Bool
end

end # module
