# SPDX-License-Identifier: PMPL-1.0-or-later
module Ingest

using ..Types
using SHA
using Dates

export ingest_source

"""
    ingest_source(path, type; title="")
Ingests a source document, hashes it for provenance, and returns a SourceDoc.
"""
function ingest_source(path::String, type::Symbol; title="Untitled")
    # Generate SHA-256 hash of the file content
    h = open(path) do io
        bytes2hex(sha256(io))
    end
    
    return SourceDoc(
        gensym("doc"),
        type,
        title,
        path,
        now(),
        h
    )
end

end # module
