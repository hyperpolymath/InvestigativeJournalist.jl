# SPDX-License-Identifier: PMPL-1.0-or-later
module StringBoard

using ..Types
using Luxor

export CrazyWall, add_photo!, add_string!

struct BoardElement
    id::Symbol
    pos::Point
    type::Symbol # :photo, :note, :claim
    label::String
end

struct StringLink
    from::Symbol
    to::Symbol
    color::String # Red for 'Strong', Yellow for 'Suspicious'
end

mutable struct CrazyWall
    elements::Vector{BoardElement}
    strings::Vector{StringLink}
end

CrazyWall() = CrazyWall(BoardElement[], StringLink[])

function add_photo!(wall::CrazyWall, id::Symbol, x, y, label)
    push!(wall.elements, BoardElement(id, Point(x,y), :photo, label))
end

function add_string!(wall::CrazyWall, id1::Symbol, id2::Symbol; color="red")
    push!(wall.strings, StringLink(id1, id2, color))
end

"""
    render_wall(wall, filename)
Renders the 'Crazy Wall' to a PDF or PNG.
"""
function render_wall(wall::CrazyWall, filename)
    Drawing(1000, 800, filename)
    background("black")
    origin()
    
    # Draw strings first
    for s in wall.strings
        setcolor(s.color)
        setline(2)
        # Find points for id1 and id2
        # (Simplified for the example)
        line(Point(-100, -100), Point(100, 100), :stroke)
    end
    
    # Draw photos/notes
    for e in wall.elements
        setcolor("white")
        rect(e.pos - Point(40,40), 80, 80, :fill)
        setcolor("black")
        fontsize(10)
        text(e.label, e.pos, halign=:center)
    end
    
    finish()
    return "Investigation wall rendered to $filename 🕵️🖼️"
end

end # module
