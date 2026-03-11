# SPDX-License-Identifier: PMPL-1.0-or-later
module AudioProduction

using ..Types

export PodcastScript, add_segment!, generate_show_notes

struct PodcastSegment
    timestamp::String
    speaker::String
    content::String
    evidence_ref::Union{Symbol, Nothing} # Link back to SourceDoc
end

struct PodcastScript
    title::String
    segments::Vector{PodcastSegment}
end

function add_segment!(script::PodcastScript, time, speaker, text, evidence=nothing)
    push!(script.segments, PodcastSegment(time, speaker, text, evidence))
end

function generate_show_notes(script::PodcastScript)
    notes = "# Show Notes: $(script.title)

"
    for s in script.segments
        notes *= "[$(s.timestamp)] **$(s.speaker)**: $(s.content)
"
        if s.evidence_ref !== nothing
            notes *= "  - *Evidence Source: $(s.evidence_ref)*
"
        end
    end
    return notes
end

end # module
