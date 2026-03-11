# SPDX-License-Identifier: PMPL-1.0-or-later
using Test
using InvestigativeJournalist
using Dates
using DataFrames

@testset "InvestigativeJournalist.jl" begin

    # -----------------------------------------------------------------------
    # Types
    # -----------------------------------------------------------------------
    @testset "Types" begin
        @testset "SourceDoc" begin
            doc = SourceDoc(
                :doc1, :document, "Leaked Memo", "/tmp/memo.pdf",
                DateTime(2026, 1, 15, 10, 30), "abc123def456"
            )
            @test doc.id == :doc1
            @test doc.source_type == :document
            @test doc.title == "Leaked Memo"
            @test doc.path_or_url == "/tmp/memo.pdf"
            @test doc.collected_at == DateTime(2026, 1, 15, 10, 30)
            @test doc.hash == "abc123def456"
        end

        @testset "SourceDoc source_type variants" begin
            for stype in [:document, :web, :interview, :leak]
                doc = SourceDoc(:d, stype, "T", "/p", now(), "h")
                @test doc.source_type == stype
            end
        end

        @testset "Claim" begin
            claim = Claim(:c1, "Company X polluted river", "Environment",
                          :doc1, DateTime(2026, 2, 1))
            @test claim.id == :c1
            @test claim.text == "Company X polluted river"
            @test claim.topic == "Environment"
            @test claim.extracted_from_doc == :doc1
            @test claim.created_at == DateTime(2026, 2, 1)
        end

        @testset "EvidenceLink" begin
            link = EvidenceLink(:c1, :doc1, :supports, 0.95, "Strong match")
            @test link.claim_id == :c1
            @test link.source_doc_id == :doc1
            @test link.support_type == :supports
            @test link.confidence == 0.95
            @test link.notes == "Strong match"

            # Test other support types
            contra = EvidenceLink(:c1, :doc2, :contradicts, 0.3, "Weak")
            @test contra.support_type == :contradicts

            nuance = EvidenceLink(:c1, :doc3, :nuances, 0.7, "Context")
            @test nuance.support_type == :nuances
        end

        @testset "EvidenceLink confidence bounds" begin
            low = EvidenceLink(:c, :d, :supports, 0.0, "")
            @test low.confidence == 0.0
            high = EvidenceLink(:c, :d, :supports, 1.0, "")
            @test high.confidence == 1.0
        end

        @testset "Entity" begin
            entity = Entity(:e1, :person, "Jane Doe", ["J. Doe", "Jane D."])
            @test entity.id == :e1
            @test entity.kind == :person
            @test entity.canonical_name == "Jane Doe"
            @test length(entity.aliases) == 2
            @test "J. Doe" in entity.aliases
        end

        @testset "Entity kind variants" begin
            for kind in [:person, :organization, :place]
                e = Entity(:e, kind, "Name", String[])
                @test e.kind == kind
            end
        end

        @testset "Event" begin
            event = Event(:ev1, DateTime(2026, 3, 1), "City Hall",
                          "Council voted on zoning", [:e1, :e2])
            @test event.id == :ev1
            @test event.location == "City Hall"
            @test event.summary == "Council voted on zoning"
            @test length(event.linked_entities) == 2
        end

        @testset "FOIARequest" begin
            foia = FOIARequest(:f1, "EPA", DateTime(2026, 1, 1), :pending,
                               DateTime(2026, 4, 1), Symbol[])
            @test foia.id == :f1
            @test foia.agency == "EPA"
            @test foia.status == :pending
            @test isempty(foia.docs_received)

            # Mutable - test mutation
            foia.status = :responded
            @test foia.status == :responded
            push!(foia.docs_received, :doc42)
            @test :doc42 in foia.docs_received
        end

        @testset "StoryDraft" begin
            draft = StoryDraft(:s1, "Breaking: Corruption Exposed",
                               ["Paragraph 1", "Paragraph 2"],
                               ["Check defamation clause"], false)
            @test draft.id == :s1
            @test draft.headline == "Breaking: Corruption Exposed"
            @test length(draft.narrative_blocks) == 2
            @test !draft.is_vetted

            # Mutable - test vetting
            draft.is_vetted = true
            @test draft.is_vetted
        end
    end

    # -----------------------------------------------------------------------
    # Claims extraction
    # -----------------------------------------------------------------------
    @testset "Claims" begin
        claim = extract_claim("The river was contaminated", :doc1; topic="Pollution")
        @test claim isa Claim
        @test claim.text == "The river was contaminated"
        @test claim.topic == "Pollution"
        @test claim.extracted_from_doc == :doc1
        @test claim.created_at <= now()

        # Default topic
        claim_default = extract_claim("Some claim text", :doc2)
        @test claim_default.topic == "General"
    end

    # -----------------------------------------------------------------------
    # Corroboration
    # -----------------------------------------------------------------------
    @testset "Corroboration" begin
        @testset "link_evidence" begin
            link = link_evidence(:claim_test, :src_test;
                                 type=:supports, confidence=0.9, notes="Verified")
            @test link isa EvidenceLink
            @test link.claim_id == :claim_test
            @test link.source_doc_id == :src_test
            @test link.support_type == :supports
            @test link.confidence == 0.9
            @test link.notes == "Verified"
        end

        @testset "link_evidence defaults" begin
            link = link_evidence(:claim_def, :src_def)
            @test link.support_type == :supports
            @test link.confidence == 1.0
            @test link.notes == ""
        end

        @testset "corroboration_report" begin
            # Add multiple links to the same claim
            link_evidence(:report_claim, :src_a; type=:supports, confidence=0.8)
            link_evidence(:report_claim, :src_b; type=:contradicts, confidence=0.4)

            report = corroboration_report(:report_claim)
            @test report isa DataFrame
            @test nrow(report) >= 2
            @test :Source in propertynames(report)
            @test :Type in propertynames(report)
            @test :Confidence in propertynames(report)
            @test :Notes in propertynames(report)
        end

        @testset "corroboration_report empty" begin
            report = corroboration_report(:nonexistent_claim_xyz)
            @test report isa DataFrame
            @test nrow(report) == 0
        end
    end

    # -----------------------------------------------------------------------
    # DocumentUnlock (shield)
    # -----------------------------------------------------------------------
    @testset "DocumentUnlock" begin
        @testset "unlock_pdf" begin
            result = unlock_pdf("/tmp/locked.pdf")
            @test result == "/tmp/locked.pdf.unlocked.pdf"
            @test endswith(result, ".unlocked.pdf")
        end

        @testset "force_extract_text" begin
            text = force_extract_text("/tmp/scan.pdf")
            @test text isa String
            @test !isempty(text)
        end
    end

    # -----------------------------------------------------------------------
    # AudioProduction
    # -----------------------------------------------------------------------
    @testset "AudioProduction" begin
        @testset "PodcastScript construction" begin
            script = PodcastScript("Deep Dive Episode 1",
                                   InvestigativeJournalist.AudioProduction.PodcastSegment[])
            @test script.title == "Deep Dive Episode 1"
            @test isempty(script.segments)
        end

        @testset "add_segment!" begin
            script = PodcastScript("Test Episode",
                                   InvestigativeJournalist.AudioProduction.PodcastSegment[])
            add_segment!(script, "00:00", "Host", "Welcome to the show")
            @test length(script.segments) == 1
            @test script.segments[1].speaker == "Host"
            @test script.segments[1].content == "Welcome to the show"
            @test script.segments[1].evidence_ref === nothing

            # With evidence reference
            add_segment!(script, "05:00", "Guest", "Here is the data", :doc99)
            @test length(script.segments) == 2
            @test script.segments[2].evidence_ref == :doc99
        end

        @testset "generate_show_notes" begin
            script = PodcastScript("Notes Test",
                                   InvestigativeJournalist.AudioProduction.PodcastSegment[])
            add_segment!(script, "00:00", "Alice", "Intro")
            add_segment!(script, "10:00", "Bob", "Key finding", :evidence1)

            notes = generate_show_notes(script)
            @test notes isa String
            @test occursin("Notes Test", notes)
            @test occursin("Alice", notes)
            @test occursin("Bob", notes)
            @test occursin("evidence1", notes)
        end
    end

    # -----------------------------------------------------------------------
    # SecureTransfer
    # -----------------------------------------------------------------------
    @testset "SecureTransfer" begin
        @testset "generate_drop_token" begin
            token = generate_drop_token("my_secret_key")
            @test token isa String
            @test length(token) == 12
            # Different calls should produce different tokens (time-dependent)
        end

        @testset "sign_evidence_pack" begin
            sig = sign_evidence_pack("abcdef123456", "private_key_data")
            @test sig isa String
            @test occursin("SIGNED_", sig)
            @test occursin("abcdef123456", sig)
            @test occursin("RSA_4096", sig)
        end
    end

    # -----------------------------------------------------------------------
    # StoryArchitect (storytelling/templates)
    # -----------------------------------------------------------------------
    @testset "StoryArchitect" begin
        @testset "StoryTemplate subtypes" begin
            @test Longform() isa StoryTemplate
            @test NewsBulletin() isa StoryTemplate
            @test Thread() isa StoryTemplate
        end

        @testset "build_story_structure Longform" begin
            structure = build_story_structure(Longform())
            @test structure isa Vector{String}
            @test length(structure) == 5
            @test occursin("Hook", structure[1])
            @test occursin("Evidence", structure[2])
            @test occursin("Narrative", structure[3])
            @test occursin("Rebuttal", structure[4])
            @test occursin("Conclusion", structure[5])
        end
    end

    # -----------------------------------------------------------------------
    # InvestigativeAnalytics (analytics/statistics)
    # -----------------------------------------------------------------------
    @testset "InvestigativeAnalytics" begin
        @testset "benfords_law_check" begin
            result = benfords_law_check([100.0, 200.0, 300.0, 150.0])
            @test haskey(result, :p_value) || hasproperty(result, :p_value)
            @test haskey(result, :is_suspicious) || hasproperty(result, :is_suspicious)
            @test result.p_value isa Float64
            @test result.is_suspicious isa Bool
        end

        @testset "find_outliers" begin
            df = DataFrame(Amount = [10, 20, 30, 1000, 15])
            result = find_outliers(df, :Amount)
            @test result isa String
        end
    end

    # -----------------------------------------------------------------------
    # BranchingTimelines
    # -----------------------------------------------------------------------
    @testset "BranchingTimelines" begin
        @testset "TimelineEvent" begin
            te = TimelineEvent(:te1, DateTime(2026, 1, 1), "Something happened", :doc1)
            @test te.id == :te1
            @test te.description == "Something happened"
            @test te.evidence_ref == :doc1
        end

        @testset "TimelineBranch" begin
            branch = TimelineBranch(:br1, "Main Timeline", nothing, TimelineEvent[])
            @test branch.id == :br1
            @test branch.name == "Main Timeline"
            @test branch.parent_id === nothing
            @test isempty(branch.events)
        end

        @testset "create_branch" begin
            branch = create_branch(:master_tl, "Master")
            @test branch isa TimelineBranch
            @test branch.id == :master_tl
            @test branch.name == "Master"
            @test branch.parent_id === nothing

            # Branch with parent
            child = create_branch(:leak_tl, "Leak Version"; parent=:master_tl)
            @test child.parent_id == :master_tl
        end

        @testset "add_event!" begin
            branch = create_branch(:ev_test_branch, "Events Test")
            result = add_event!(branch, "Document leaked", :doc5;
                                time=DateTime(2026, 6, 15))
            @test result isa String
            @test occursin("Events Test", result)
            @test length(branch.events) == 1
            @test branch.events[1].description == "Document leaked"
            @test branch.events[1].evidence_ref == :doc5

            # Add second event
            add_event!(branch, "Follow-up interview", :doc6)
            @test length(branch.events) == 2
        end
    end

    # -----------------------------------------------------------------------
    # StringBoard (CrazyWall)
    # -----------------------------------------------------------------------
    @testset "StringBoard" begin
        @testset "CrazyWall construction" begin
            wall = CrazyWall()
            @test isempty(wall.elements)
            @test isempty(wall.strings)
        end

        @testset "add_photo!" begin
            wall = CrazyWall()
            add_photo!(wall, :suspect1, 100, 200, "Person A")
            @test length(wall.elements) == 1
            @test wall.elements[1].id == :suspect1
            @test wall.elements[1].label == "Person A"
            @test wall.elements[1].type == :photo

            add_photo!(wall, :suspect2, -50, 100, "Person B")
            @test length(wall.elements) == 2
        end

        @testset "add_string!" begin
            wall = CrazyWall()
            add_photo!(wall, :a, 0, 0, "A")
            add_photo!(wall, :b, 100, 100, "B")
            add_string!(wall, :a, :b)
            @test length(wall.strings) == 1
            @test wall.strings[1].from == :a
            @test wall.strings[1].to == :b
            @test wall.strings[1].color == "red"  # default

            add_string!(wall, :a, :b; color="yellow")
            @test length(wall.strings) == 2
            @test wall.strings[2].color == "yellow"
        end
    end

    # -----------------------------------------------------------------------
    # SystemicForensics
    # -----------------------------------------------------------------------
    @testset "SystemicForensics" begin
        @testset "model_instability_context" begin
            result = model_instability_context("test data")
            @test result isa String
        end

        @testset "test_causal_pathway" begin
            result = test_causal_pathway(nothing, :corruption, :collapse)
            @test result.belief isa Float64
            @test result.plausibility isa Float64
            @test 0.0 <= result.belief <= 1.0
            @test 0.0 <= result.plausibility <= 1.0
        end

        @testset "assess_black_swan" begin
            result = assess_black_swan("Market crash 2026")
            @test result isa String
        end
    end

    # -----------------------------------------------------------------------
    # MediaPro (audio/image processing)
    # -----------------------------------------------------------------------
    @testset "MediaPro" begin
        @testset "isolate_signal" begin
            result = isolate_signal("test_image", (100, 200))
            @test result == "test_image"  # returns input as placeholder
        end

        @testset "denoise_audio" begin
            result = denoise_audio("raw_audio_data")
            @test result isa String
            @test result == "CLEAN_AUDIO_STREAM"
        end

        @testset "enhance_clarity" begin
            result = enhance_clarity("photo_data")
            @test result == "photo_data"  # returns input as placeholder
        end
    end

    # -----------------------------------------------------------------------
    # MediaForensics
    # -----------------------------------------------------------------------
    @testset "MediaForensics" begin
        @testset "verify_image_integrity" begin
            result = verify_image_integrity("/tmp/photo.jpg")
            @test hasproperty(result, :has_metadata) || haskey(result, :has_metadata)
            @test hasproperty(result, :tamper_probability) || haskey(result, :tamper_probability)
            @test result.tamper_probability isa Float64
        end

        @testset "detect_ai_artifacts" begin
            result = detect_ai_artifacts("/tmp/suspect_image.png")
            @test hasproperty(result, :is_synthetic_probability)
            @test hasproperty(result, :confidence)
            @test result.is_synthetic_probability isa Float64
            @test result.confidence isa Float64
        end
    end

    # -----------------------------------------------------------------------
    # InteropBridge
    # -----------------------------------------------------------------------
    @testset "InteropBridge" begin
        @testset "run_r_script" begin
            result = run_r_script("summary(mtcars)")
            @test result == "RESULT_FROM_R"
        end

        @testset "export_to_stata" begin
            # Should not error; returns nothing (prints only)
            @test export_to_stata(nothing, "output.dta") === nothing
        end

        @testset "export_to_spss" begin
            @test export_to_spss(nothing, "output.sav") === nothing
        end
    end

    # -----------------------------------------------------------------------
    # VeriSimBridge
    # -----------------------------------------------------------------------
    @testset "VeriSimBridge" begin
        @testset "register_investigation_hexad" begin
            claim = Claim(:vc1, "Test claim", "Testing", :doc1, DateTime(2026, 1, 1))
            hexad = register_investigation_hexad(claim, :evidence1)
            @test hexad isa Dict
            @test haskey(hexad, :id)
            @test haskey(hexad, :modalities)
            @test hexad[:id] == string(:vc1)
            @test haskey(hexad[:modalities], :semantic)
            @test hexad[:modalities][:semantic] == "Test claim"
        end

        @testset "vql_query" begin
            result = vql_query("SELECT * FROM investigation WHERE DRIFT < 0.1")
            @test result isa Vector
        end
    end

end # top-level testset
