# SPDX-License-Identifier: PMPL-1.0-or-later
module Claims

using ..Types
using Dates

export extract_claim

function extract_claim(text::String, source_id::Symbol; topic="General")
    return Claim(
        gensym("claim"),
        text,
        topic,
        source_id,
        now()
    )
end

end # module
