using InvestigativeJournalist
using Dates

# 1. Ingest a leaked document (Simulated)
# We'll create a dummy file for the example
path = "leak_01.txt"
open(path, "w") do io println(io, "Secret data: The CEO lied about the 2025 revenue.") end

doc = ingest_source(path, :leak, title="Internal Memo")
println("Ingested $(doc.title) [Hash: $(doc.hash)]")

# 2. Extract a claim from the document
claim = extract_claim("CEO lied about 2025 revenue", doc.id, topic="Financial Fraud")
println("Extracted Claim: '$(claim.text)'")

# 3. Corroborate with another source
# Let's say we have an interview that confirms this
interview = SourceDoc(:int_01, :interview, "Interview with Whistleblower", "office_recording.mp3", now(), "fake_hash")

link_evidence(claim.id, interview.id, type=:supports, confidence=0.9, notes="Direct witness testimony.")

# 4. Generate the Corroboration Audit Report
report = corroboration_report(claim.id)
println("
--- Corroboration Audit for Story Draft ---")
display(report)

println("
Evidence is locked. Story is ready for legal review. 🔍⚖️")
rm(path) # Cleanup
