# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# BenchmarkTools benchmarks for InvestigativeJournalist.jl.

using BenchmarkTools
using InvestigativeJournalist
using Dates

println("=== InvestigativeJournalist.jl Benchmarks ===")

# --- Type construction ---

println("\n-- Type construction --")

b_sourcedoc = @benchmark SourceDoc(:doc, :leak, "T", "/p", now(), "h")
println("SourceDoc construction: ", median(b_sourcedoc))

b_claim = @benchmark extract_claim("A claim", :doc1; topic="General")
println("extract_claim: ", median(b_claim))

b_link = @benchmark link_evidence(:c1, :d1; type=:supports, confidence=0.9)
println("link_evidence: ", median(b_link))

# --- Corroboration report ---

println("\n-- Corroboration report --")

# Small: no links for unknown claim.
b_report_empty = @benchmark corroboration_report(:nonexistent_bench_claim)
println("corroboration_report (empty): ", median(b_report_empty))

# Medium: report with pre-populated links.
for i in 1:10
    link_evidence(:bench_claim_medium, Symbol("src_$(i)");
                  type=:supports, confidence=rand())
end
b_report_medium = @benchmark corroboration_report(:bench_claim_medium)
println("corroboration_report (10 links): ", median(b_report_medium))

# --- Audio production ---

println("\n-- Podcast script assembly --")

function build_script(n_segments::Int)
    script = PodcastScript("Bench Episode",
                           InvestigativeJournalist.AudioProduction.PodcastSegment[])
    for i in 1:n_segments
        add_segment!(script, "$(i):00", "Speaker$(i)", "Content block $(i)")
    end
    return script
end

b_script_small  = @benchmark build_script(5)
b_script_medium = @benchmark build_script(20)
b_script_large  = @benchmark build_script(100)
println("build_script(5 segments):   ", median(b_script_small))
println("build_script(20 segments):  ", median(b_script_medium))
println("build_script(100 segments): ", median(b_script_large))

# --- Forensics ---

println("\n-- Media forensics --")

b_verify = @benchmark verify_image_integrity("/tmp/bench_photo.jpg")
println("verify_image_integrity: ", median(b_verify))

b_detect = @benchmark detect_ai_artifacts("/tmp/bench_image.png")
println("detect_ai_artifacts: ", median(b_detect))
