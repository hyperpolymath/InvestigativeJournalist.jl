# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# Property-based invariant tests for InvestigativeJournalist.jl.

using Test
using InvestigativeJournalist
using Dates

@testset "Property-Based Tests" begin

    @testset "EvidenceLink confidence is always in [0, 1]" begin
        for _ in 1:50
            conf = rand()  # uniform on [0, 1)
            link = EvidenceLink(:c, :d, :supports, conf, "")
            @test 0.0 <= link.confidence <= 1.0
        end
    end

    @testset "extract_claim always creates Claim with correct source doc" begin
        for i in 1:50
            doc_id = Symbol("doc_$(i)")
            claim = extract_claim("Claim text $(i)", doc_id; topic="T$(i)")
            @test claim.extracted_from_doc == doc_id
            @test claim.text == "Claim text $(i)"
            @test claim.topic == "T$(i)"
            @test claim.created_at <= now()
        end
    end

    @testset "link_evidence default type is :supports" begin
        for i in 1:50
            link = link_evidence(Symbol("cl_$(i)"), Symbol("src_$(i)"))
            @test link.support_type == :supports
            @test link.confidence == 1.0
        end
    end

    @testset "SourceDoc: source_type roundtrips correctly" begin
        types = [:document, :web, :interview, :leak]
        for _ in 1:50
            stype = rand(types)
            doc = SourceDoc(Symbol("d_$(rand(1:9999))"), stype,
                            "Title", "/path", now(), "hash")
            @test doc.source_type == stype
        end
    end

    @testset "StoryTemplate subtypes: build_story_structure is non-empty" begin
        templates = [Longform(), NewsBulletin(), Thread()]
        for _ in 1:50
            t = rand(templates)
            structure = build_story_structure(t)
            @test structure isa Vector{String}
            @test !isempty(structure)
        end
    end

    @testset "benfords_law_check: p_value is Float64 in [0, 1]" begin
        for _ in 1:50
            n = rand(4:20)
            data = rand(1.0:999.0, n)
            result = benfords_law_check(data)
            @test result.p_value isa Float64
            @test 0.0 <= result.p_value <= 1.0
            @test result.is_suspicious isa Bool
        end
    end

    @testset "generate_drop_token always returns 12-character string" begin
        for _ in 1:50
            key = "key_$(rand(1:999999))"
            token = generate_drop_token(key)
            @test token isa String
            @test length(token) == 12
        end
    end

    @testset "sign_evidence_pack always contains SIGNED_ prefix" begin
        for _ in 1:50
            hash_val = "hash_$(rand(1:999999))"
            sig = sign_evidence_pack(hash_val, "privkey")
            @test startswith(sig, "SIGNED_")
            @test occursin(hash_val, sig)
        end
    end

    @testset "CrazyWall: elements grow monotonically with add_photo!" begin
        for _ in 1:20
            wall = CrazyWall()
            n = rand(1:10)
            for i in 1:n
                add_photo!(wall, Symbol("e_$(i)"), i * 10, i * 5, "Label $(i)")
            end
            @test length(wall.elements) == n
        end
    end

end
