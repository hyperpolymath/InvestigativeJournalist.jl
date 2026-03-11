# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Document parsing and analysis for investigative journalism.
# Extracts entities, detects suspicious clauses, analyses job descriptions
# for bias indicators, and compares policy document versions.

module Parsers

using ..Types
using TextAnalysis
using StringDistances

export parse_contract, parse_job_description, compare_policies

# Legal terms that may indicate restrictive or predatory clauses
const RED_FLAG_TERMS = [
    "indemnify", "non-disclosure", "irrevocable", "arbitration",
    "non-compete", "liquidated damages", "waive", "severability",
    "force majeure", "hold harmless", "sole discretion",
    "at-will", "right to terminate", "binding arbitration",
    "class action waiver", "jury trial waiver",
    "intellectual property assignment", "work for hire",
    "perpetual license", "worldwide license",
    "no expectation of privacy", "consent to monitoring",
]

# Patterns for entity extraction from legal text
const ENTITY_PATTERNS = [
    r"(?:hereinafter|herein)\s+(?:referred to as|called)\s+[\"']([^\"']+)[\"']"i,
    r"(?:between|among)\s+([A-Z][A-Za-z\s&,.]+?)(?:\s+and\s+|\s*,\s*)"i,
    r"(?:Party|party)\s+[\"']?([A-Z][A-Za-z\s]+)[\"']?"i,
    r"([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\s*(?:Inc\.|LLC|Ltd\.|Corp\.|Co\.)"i,
    r"(?:the\s+)?\"([A-Z][^\"]+)\"\s*(?:shall|means|refers)"i,
]

# Job description bias / ghost job indicators
const JOB_BIAS_INDICATORS = Dict{String, Tuple{Symbol, String}}(
    "rockstar"         => (:gendered_language, "Gendered/exclusionary language: 'rockstar'"),
    "ninja"            => (:gendered_language, "Gendered/exclusionary language: 'ninja'"),
    "guru"             => (:gendered_language, "Gendered/exclusionary language: 'guru'"),
    "wizard"           => (:gendered_language, "Gendered/exclusionary language: 'wizard'"),
    "10x"              => (:unrealistic,       "Unrealistic expectations: '10x' developer"),
    "fast-paced environment" => (:burnout_risk, "Burnout signal: 'fast-paced environment'"),
    "wear many hats"   => (:understaffed,      "Understaffing signal: 'wear many hats'"),
    "work hard play hard" => (:burnout_risk,    "Burnout signal: 'work hard play hard'"),
    "competitive salary" => (:pay_opacity,      "Pay opacity: salary not disclosed"),
    "family"           => (:boundary_erosion,   "Boundary erosion: referring to company as 'family'"),
    "self-starter"     => (:no_mentorship,      "May indicate lack of mentorship"),
    "hit the ground running" => (:no_onboarding, "May indicate no onboarding process"),
    "unlimited pto"    => (:guilt_pto,          "Unlimited PTO often leads to less time off"),
)

# Ghost job indicators (job postings that may not represent real openings)
const GHOST_JOB_SIGNALS = [
    (r"posted\s+(\d+)\+?\s+days?\s+ago"i, "Job posted for extended period"),
    (r"always\s+accepting"i, "Perpetual posting ('always accepting')"),
    (r"talent\s+pool"i, "Talent pool collection, not specific opening"),
    (r"future\s+openings?"i, "Future opening, not current vacancy"),
]

"""
    parse_contract(text::String) -> NamedTuple

Extract key legal entities and analyse contract text for suspicious or
restrictive clauses.

Performs:
1. **Entity extraction**: identifies parties, companies, and defined terms
2. **Red flag detection**: searches for restrictive legal terms
3. **Clause density analysis**: measures legal complexity via sentence length
4. **Section identification**: detects major contract sections

# Arguments
- `text`: the full contract text

# Returns
A named tuple with:
- `entities::Vector{String}` - extracted party/entity names
- `red_flags::Vector{String}` - suspicious terms found
- `word_count::Int` - total word count
- `avg_sentence_length::Float64` - average words per sentence
- `sections::Vector{String}` - identified section headings
- `risk_level::Symbol` - overall risk assessment (:low, :medium, :high)
"""
function parse_contract(text::String)
    isempty(strip(text)) && return (
        entities = String[], red_flags = String[], word_count = 0,
        avg_sentence_length = 0.0, sections = String[], risk_level = :low
    )

    doc = StringDocument(text)
    lower_text = lowercase(text)

    # Entity extraction
    entities = String[]
    for pattern in ENTITY_PATTERNS
        for m in eachmatch(pattern, text)
            entity = strip(m[1])
            if length(entity) > 2 && length(entity) < 100 && !(entity in entities)
                push!(entities, entity)
            end
        end
    end

    # Red flag term detection
    red_flags = String[]
    for term in RED_FLAG_TERMS
        if occursin(term, lower_text)
            push!(red_flags, term)
        end
    end

    # Word and sentence analysis
    words = tokens(doc)
    word_count = length(words)

    # Sentence splitting (approximate)
    sentences = split(text, r"[.!?]+\s+")
    sentence_lengths = [length(split(s)) for s in sentences if !isempty(strip(s))]
    avg_sentence_length = isempty(sentence_lengths) ? 0.0 : sum(sentence_lengths) / length(sentence_lengths)

    # Section heading detection
    sections = String[]
    for line in split(text, '\n')
        stripped = strip(line)
        # Common section patterns: numbered sections, all-caps headings
        if occursin(r"^\d+\.\s+[A-Z]", stripped) ||
           occursin(r"^(?:SECTION|ARTICLE|CLAUSE)\s+\d+", stripped) ||
           (length(stripped) > 3 && length(stripped) < 80 && uppercase(stripped) == stripped &&
            !occursin(r"[.,:;]", stripped))
            push!(sections, stripped)
        end
    end

    # Risk assessment
    risk_score = length(red_flags)
    risk_score += avg_sentence_length > 40 ? 2 : 0  # overly complex language
    risk_score += occursin("binding arbitration", lower_text) ? 3 : 0
    risk_score += occursin("class action waiver", lower_text) ? 3 : 0

    risk_level = risk_score >= 8 ? :high : (risk_score >= 4 ? :medium : :low)

    return (
        entities = entities,
        red_flags = red_flags,
        word_count = word_count,
        avg_sentence_length = round(avg_sentence_length; digits=1),
        sections = sections,
        risk_level = risk_level
    )
end

"""
    parse_job_description(text::String) -> NamedTuple

Analyse a job description for bias indicators, exclusionary language,
and 'ghost job' signals (postings that may not represent real openings).

# Arguments
- `text`: the job description text

# Returns
A named tuple with:
- `jargon_score::Int` - count of problematic terms found
- `is_suspicious::Bool` - whether the posting shows ghost job signals
- `bias_indicators::Vector{NamedTuple}` - specific bias findings
- `ghost_signals::Vector{String}` - ghost job indicators found
- `missing_info::Vector{String}` - important information absent from posting
"""
function parse_job_description(text::String)
    lower_text = lowercase(text)

    # Bias indicator detection
    bias_indicators = NamedTuple{(:category, :description), Tuple{Symbol, String}}[]
    jargon_score = 0

    for (term, (category, description)) in JOB_BIAS_INDICATORS
        if occursin(term, lower_text)
            push!(bias_indicators, (category=category, description=description))
            jargon_score += 1
        end
    end

    # Ghost job signal detection
    ghost_signals = String[]
    for (pattern, description) in GHOST_JOB_SIGNALS
        if occursin(pattern, lower_text)
            push!(ghost_signals, description)
        end
    end

    # Check for missing important information
    missing_info = String[]
    if !occursin(r"\$[\d,]+|salary|compensation|pay\s+range"i, text)
        push!(missing_info, "No salary/compensation information")
    end
    if !occursin(r"remote|hybrid|on-?site|in-?office|location"i, text)
        push!(missing_info, "No work location/modality specified")
    end
    if !occursin(r"report(?:s|ing)\s+to|team\s+size|department"i, text)
        push!(missing_info, "No reporting structure or team information")
    end
    if !occursin(r"benefits|health|dental|401k|pension|pto|vacation"i, text)
        push!(missing_info, "No benefits information")
    end

    is_suspicious = jargon_score > 2 || !isempty(ghost_signals) || length(missing_info) >= 3

    return (
        jargon_score = jargon_score,
        is_suspicious = is_suspicious,
        bias_indicators = bias_indicators,
        ghost_signals = ghost_signals,
        missing_info = missing_info
    )
end

"""
    compare_policies(old_text::String, new_text::String) -> NamedTuple

Compare two versions of a policy document to identify changes, including
hidden modifications that may not be apparent from a casual reading.

Uses Levenshtein distance for overall similarity and performs paragraph-level
diffing to identify specific changed, added, and removed sections.

# Arguments
- `old_text`: the original/previous version of the policy
- `new_text`: the updated/current version of the policy

# Returns
A named tuple with:
- `similarity::Float64` - overall text similarity (0.0 = completely different, 1.0 = identical)
- `has_major_changes::Bool` - whether significant structural changes were detected
- `added_paragraphs::Vector{String}` - paragraphs present only in new version
- `removed_paragraphs::Vector{String}` - paragraphs present only in old version
- `changed_sections::Int` - count of paragraphs with modifications
- `summary::String` - human-readable change summary
"""
function compare_policies(old::String, new::String)
    # Overall similarity using normalised Levenshtein distance
    similarity = compare(old, new, Levenshtein())

    # Paragraph-level comparison
    old_paras = _split_paragraphs(old)
    new_paras = _split_paragraphs(new)

    old_set = Set(strip.(old_paras))
    new_set = Set(strip.(new_paras))

    added = [p for p in new_paras if !(strip(p) in old_set) && !isempty(strip(p))]
    removed = [p for p in old_paras if !(strip(p) in new_set) && !isempty(strip(p))]

    # Count paragraphs that were modified (similar but not identical)
    changed = 0
    for old_p in old_paras
        isempty(strip(old_p)) && continue
        strip(old_p) in new_set && continue
        # Check if there's a close match in the new version
        for new_p in new_paras
            isempty(strip(new_p)) && continue
            strip(new_p) in old_set && continue
            para_sim = compare(strip(old_p), strip(new_p), Levenshtein())
            if para_sim > 0.6 && para_sim < 1.0
                changed += 1
                break
            end
        end
    end

    has_major_changes = similarity < 0.8 || length(added) > 3 || length(removed) > 3 || changed > 5

    # Build summary
    parts = String[]
    similarity < 0.95 && push!(parts, "$(round((1-similarity)*100; digits=1))% of text changed")
    !isempty(added) && push!(parts, "$(length(added)) paragraph(s) added")
    !isempty(removed) && push!(parts, "$(length(removed)) paragraph(s) removed")
    changed > 0 && push!(parts, "$(changed) paragraph(s) modified")
    summary = isempty(parts) ? "No significant changes detected" : join(parts, "; ")

    return (
        similarity = round(similarity; digits=4),
        has_major_changes = has_major_changes,
        added_paragraphs = added,
        removed_paragraphs = removed,
        changed_sections = changed,
        summary = summary
    )
end

"""Split text into paragraphs (sequences of non-empty lines)."""
function _split_paragraphs(text::String)
    paragraphs = String[]
    current = String[]

    for line in split(text, '\n')
        if isempty(strip(line))
            if !isempty(current)
                push!(paragraphs, join(current, '\n'))
                empty!(current)
            end
        else
            push!(current, line)
        end
    end

    if !isempty(current)
        push!(paragraphs, join(current, '\n'))
    end

    return paragraphs
end

end # module
