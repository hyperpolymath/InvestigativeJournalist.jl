# SPDX-License-Identifier: PMPL-1.0-or-later
module BranchingTimelines

using Dates

export TimelineBranch, TimelineEvent, add_event!, create_branch

struct TimelineEvent
    id::Symbol
    timestamp::DateTime
    description::String
    evidence_ref::Symbol
end

mutable struct TimelineBranch
    id::Symbol
    name::String
    parent_id::Union{Symbol, Nothing}
    events::Vector{TimelineEvent}
end

const TIMELINE_MASTER = Dict{Symbol, TimelineBranch}()

function create_branch(id::Symbol, name::String; parent=nothing)
    branch = TimelineBranch(id, name, parent, TimelineEvent[])
    TIMELINE_MASTER[id] = branch
    return branch
end

function add_event!(branch::TimelineBranch, desc::String, evidence::Symbol; time=now())
    event = TimelineEvent(gensym("event"), time, desc, evidence)
    push!(branch.events, event)
    return "Event added to branch '$(branch.name)'"
end

"""
    visualize_git_timeline()
Prints an ASCII 'git-style' branching timeline to the console.
"""
function visualize_git_timeline()
    # In a real implementation, this would use a graph renderer
    println("MASTER:  *---*---*---*")
    println("LEAK_V1:      \_*___*")
    println("ALT_HIST:          \_*")
end

end # module
