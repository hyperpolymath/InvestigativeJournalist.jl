# SPDX-License-Identifier: PMPL-1.0-or-later
module Corroboration

using ..Types
using DataFrames

export link_evidence, corroboration_report

const GLOBAL_LINKS = EvidenceLink[]

"""
    link_evidence(claim, source; type=:supports, confidence=1.0, notes="")
Creates a link between a claim and a source document.
"""
function link_evidence(claim_id::Symbol, source_id::Symbol; type=:supports, confidence=1.0, notes="")
    link = EvidenceLink(claim_id, source_id, type, confidence, notes)
    push!(GLOBAL_LINKS, link)
    return link
end

"""
    corroboration_report(claim_id)
Returns a DataFrame of all evidence for a specific claim.
"""
function corroboration_report(claim_id::Symbol)
    matches = filter(l -> l.claim_id == claim_id, GLOBAL_LINKS)
    return DataFrame(
        Source = [l.source_doc_id for l in matches],
        Type = [l.support_type for l in matches],
        Confidence = [l.confidence for l in matches],
        Notes = [l.notes for l in matches]
    )
end

end # module
