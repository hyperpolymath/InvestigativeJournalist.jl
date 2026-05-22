# SPDX-License-Identifier: MPL-2.0
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
