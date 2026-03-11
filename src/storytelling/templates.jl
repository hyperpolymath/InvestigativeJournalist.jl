# SPDX-License-Identifier: PMPL-1.0-or-later
module StoryArchitect

using ..Types

export StoryTemplate, Longform, NewsBulletin, Thread, build_story_structure

abstract type StoryTemplate end

struct Longform <: StoryTemplate end
struct NewsBulletin <: StoryTemplate end
struct Thread <: StoryTemplate end

function build_story_structure(::Longform)
    return [
        "The Hook (The Finding)",
        "The Evidence (Data & Docs)",
        "The Narrative (Human Impact)",
        "The Rebuttal (Target Response)",
        "The Conclusion (The Stakes)"
    ]
end

end # module
