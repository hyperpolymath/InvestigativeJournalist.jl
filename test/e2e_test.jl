# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# E2E pipeline tests for InvestigativeJournalist.jl.
# Tests the full investigation lifecycle: document ingestion → claim extraction →
# evidence linking → corroboration report → story drafting.

using Test
using InvestigativeJournalist
using Dates

@testset "E2E Pipeline Tests" begin

    @testset "Full pipeline: document → claim → evidence → report" begin
        # Step 1: create a source document.
        doc = SourceDoc(
            :leak_001, :leak, "Whistleblower Memo",
            "/secure/docs/memo.pdf",
            DateTime(2026, 1, 10, 9, 0), "sha256:abcdef1234"
        )
        @test doc.id == :leak_001
        @test doc.source_type == :leak

        # Step 2: extract a claim from the document.
        claim = extract_claim("Company X discharged toxins into the river", :leak_001;
                              topic="Environmental Crime")
        @test claim isa Claim
        @test claim.extracted_from_doc == :leak_001
        @test claim.topic == "Environmental Crime"

        # Step 3: link corroborating evidence.
        link_a = link_evidence(claim.id, :leak_001;
                               type=:supports, confidence=0.95, notes="Primary source")
        link_b = link_evidence(claim.id, :corroboration_doc_001;
                               type=:supports, confidence=0.80, notes="Corroborating memo")

        @test link_a.claim_id == claim.id
        @test link_b.confidence == 0.80

        # Step 4: generate corroboration report.
        report = corroboration_report(claim.id)
        @test nrow(report) >= 2
        @test :Source in propertynames(report)
        @test :Confidence in propertynames(report)
    end

    @testset "Full pipeline: timeline construction" begin
        # Build a timeline of events for an investigation.
        branch = create_branch(:main_tl, "Main Investigation Timeline")
        @test branch.id == :main_tl

        add_event!(branch, "Whistleblower contacts journalist", :doc_whistleblower;
                   time=DateTime(2026, 1, 5))
        add_event!(branch, "Documents obtained via FOIA", :doc_foia;
                   time=DateTime(2026, 2, 1))
        add_event!(branch, "Source corroborates claim", :doc_corroboration;
                   time=DateTime(2026, 2, 15))

        @test length(branch.events) == 3
        @test branch.events[1].description == "Whistleblower contacts journalist"
        @test branch.events[3].evidence_ref == :doc_corroboration
    end

    @testset "Full pipeline: podcast script assembly" begin
        # Produce a structured podcast from investigation findings.
        script = PodcastScript("Exposé: The River Poisoning",
                               InvestigativeJournalist.AudioProduction.PodcastSegment[])
        add_segment!(script, "00:00", "Host", "Welcome to Deep Dive Investigations.")
        add_segment!(script, "02:30", "Reporter", "What the documents reveal.", :leak_001)
        add_segment!(script, "15:00", "Host", "Our conclusions and call to action.")

        @test length(script.segments) == 3
        notes = generate_show_notes(script)
        @test occursin("Exposé", notes)
        @test occursin("Reporter", notes)
    end

    @testset "Error handling: empty corroboration report for unknown claim" begin
        report = corroboration_report(:completely_unknown_claim_xyz_e2e)
        @test nrow(report) == 0
    end

    @testset "Error handling: unlock_pdf returns deterministic path" begin
        result = unlock_pdf("/data/classified.pdf")
        @test result == "/data/classified.pdf.unlocked.pdf"
        @test endswith(result, ".unlocked.pdf")
    end

    @testset "Round-trip consistency: CrazyWall photo → string link" begin
        wall = CrazyWall()
        add_photo!(wall, :suspect_a, 0, 0, "Suspect A")
        add_photo!(wall, :company_b, 200, 100, "Company B")
        add_string!(wall, :suspect_a, :company_b; color="red")

        @test length(wall.elements) == 2
        @test length(wall.strings) == 1
        @test wall.strings[1].from == :suspect_a
        @test wall.strings[1].to == :company_b
        @test wall.strings[1].color == "red"
    end

    @testset "Round-trip consistency: FOIA request lifecycle" begin
        foia = FOIARequest(:foia_e2e, "EPA", DateTime(2026, 1, 1), :pending,
                           DateTime(2026, 4, 30), Symbol[])
        @test foia.status == :pending
        foia.status = :responded
        push!(foia.docs_received, :doc_epa_response)
        @test foia.status == :responded
        @test :doc_epa_response in foia.docs_received
    end

end
