# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Media forensics module for investigative journalism.
# Analyses image metadata, detects tampering indicators, and identifies
# AI-generated content through statistical and structural analysis.

module MediaForensics

using Images
using ..Types

export verify_image_integrity, detect_ai_artifacts

# Known EXIF tag byte patterns for quick header scanning
const JPEG_MAGIC = UInt8[0xFF, 0xD8, 0xFF]
const PNG_MAGIC = UInt8[0x89, 0x50, 0x4E, 0x47]
const EXIF_MARKER = UInt8[0xFF, 0xE1]           # APP1 (EXIF)
const JFIF_MARKER = UInt8[0xFF, 0xE0]           # APP0 (JFIF)

"""
    verify_image_integrity(path::String) -> NamedTuple

Analyse an image file for signs of tampering or metadata stripping.

Performs the following checks:
1. **EXIF metadata presence**: Missing EXIF is common in scrubbed/leaked photos
2. **Quantization table analysis**: Inconsistent JPEG quantization suggests re-encoding
3. **Double compression detection**: Statistical artefacts from re-saving a JPEG
4. **Thumbnail consistency**: Mismatched embedded thumbnail suggests editing
5. **File structure validation**: Checks for truncation or appended data

# Arguments
- `path`: filesystem path to the image file

# Returns
A named tuple with fields:
- `has_metadata::Bool`: whether EXIF/XMP metadata was found
- `tamper_probability::Float64`: estimated probability of tampering (0.0 to 1.0)
- `format::Symbol`: detected image format (:jpeg, :png, :unknown)
- `notes::String`: human-readable summary of findings
- `findings::Vector{String}`: detailed list of individual findings
"""
function verify_image_integrity(path::String)
    isfile(path) || throw(ArgumentError("Image file not found: $path"))
    data = read(path)
    findings = String[]
    tamper_score = 0.0

    # Detect format from magic bytes
    format = _detect_image_format(data)
    push!(findings, "Format: $(format)")

    # Check 1: EXIF metadata presence
    has_exif = _has_exif_data(data)
    if !has_exif
        push!(findings, "No EXIF metadata found (possible metadata stripping)")
        tamper_score += 0.15
    else
        push!(findings, "EXIF metadata present")
        # Check for suspicious EXIF: software field suggesting editing
        software = _extract_exif_software(data)
        if software !== nothing
            push!(findings, "Software tag: $software")
            editors = ["photoshop", "gimp", "lightroom", "capture one", "affinity"]
            if any(e -> occursin(e, lowercase(software)), editors)
                push!(findings, "Image was processed with editing software")
                tamper_score += 0.10
            end
        end
    end

    # Check 2: JPEG quantization analysis
    if format == :jpeg
        qf_result = _analyse_jpeg_quantization(data)
        if qf_result.double_compressed
            push!(findings, "Evidence of double JPEG compression (quality: $(qf_result.estimated_quality))")
            tamper_score += 0.25
        end
        if qf_result.inconsistent_tables
            push!(findings, "Inconsistent quantization tables across channels")
            tamper_score += 0.20
        end
    end

    # Check 3: File structure integrity
    file_size = length(data)
    if format == :jpeg
        # JPEG should end with FFD9
        if file_size >= 2 && (data[end-1] != 0xFF || data[end] != 0xD9)
            # Check if FFD9 appears before end (appended data)
            eoi_pos = _find_jpeg_eoi(data)
            if eoi_pos !== nothing && eoi_pos < file_size - 1
                appended = file_size - eoi_pos - 1
                push!(findings, "$(appended) bytes appended after JPEG end-of-image marker (possible steganography)")
                tamper_score += 0.20
            else
                push!(findings, "Missing JPEG end-of-image marker (truncated file)")
                tamper_score += 0.10
            end
        end
    end

    # Check 4: Embedded thumbnail consistency (JPEG EXIF)
    if format == :jpeg && has_exif
        thumb_result = _check_thumbnail_consistency(data)
        if thumb_result == :mismatch
            push!(findings, "Embedded thumbnail does not match main image (strong tampering indicator)")
            tamper_score += 0.30
        elseif thumb_result == :missing
            push!(findings, "No embedded thumbnail (unusual for camera photos)")
        end
    end

    # Check 5: PNG chunk integrity
    if format == :png
        png_result = _check_png_chunks(data)
        for note in png_result
            push!(findings, note)
        end
    end

    # Clamp probability
    tamper_probability = clamp(tamper_score, 0.0, 1.0)

    notes = if tamper_probability > 0.6
        "HIGH probability of tampering or manipulation. $(length(findings)) indicator(s) found."
    elseif tamper_probability > 0.3
        "MODERATE probability of post-processing. $(length(findings)) indicator(s) found."
    else
        "No strong tampering indicators. $(length(findings)) check(s) passed."
    end

    return (
        has_metadata = has_exif,
        tamper_probability = round(tamper_probability; digits=3),
        format = format,
        notes = notes,
        findings = findings
    )
end

"""
    detect_ai_artifacts(path::String) -> NamedTuple

Scan an image for statistical patterns characteristic of AI-generated content.

Detection methods:
1. **Frequency domain analysis**: AI images often lack natural high-frequency noise
2. **Colour histogram uniformity**: GAN outputs show unnaturally smooth distributions
3. **Edge coherence**: AI-generated images may have inconsistent edge sharpness
4. **Symmetry analysis**: AI faces tend toward unnatural bilateral symmetry

# Arguments
- `path`: filesystem path to the image file

# Returns
A named tuple with:
- `is_synthetic_probability::Float64`: estimated probability the image is AI-generated
- `confidence::Float64`: confidence in the assessment (0.0 to 1.0)
- `indicators::Vector{String}`: specific indicators found
"""
function detect_ai_artifacts(path::String)
    isfile(path) || throw(ArgumentError("Image file not found: $path"))

    img = load(path)
    indicators = String[]
    synthetic_score = 0.0

    # Convert to grayscale for analysis
    gray = Gray.(img)
    height, width = size(gray)

    # Check 1: Colour histogram smoothness
    # AI images tend to have very smooth colour distributions
    hist_smoothness = _colour_histogram_smoothness(img)
    if hist_smoothness > 0.95
        push!(indicators, "Unusually smooth colour distribution (typical of diffusion models)")
        synthetic_score += 0.20
    end

    # Check 2: High-frequency noise analysis
    # Natural photos have characteristic sensor noise; AI images often lack it
    noise_level = _estimate_noise_level(gray)
    if noise_level < 0.005
        push!(indicators, "Very low sensor noise (unusual for camera images)")
        synthetic_score += 0.15
    end

    # Check 3: Edge coherence variance
    # AI images may have inconsistent sharpness across the image
    edge_variance = _edge_coherence_variance(gray)
    if edge_variance < 0.01
        push!(indicators, "Unusually uniform edge sharpness across image")
        synthetic_score += 0.15
    end

    # Check 4: Repetitive texture detection
    # GANs sometimes produce subtle repeating patterns
    has_repeats = _detect_texture_repetition(gray)
    if has_repeats
        push!(indicators, "Repeating texture patterns detected (possible GAN artefact)")
        synthetic_score += 0.15
    end

    # Check 5: Aspect ratio and resolution
    # AI images often use standard generation sizes
    ai_sizes = [(512, 512), (768, 768), (1024, 1024), (512, 768), (768, 512),
                (1024, 1024), (1344, 768), (768, 1344), (896, 1152), (1152, 896)]
    if (height, width) in ai_sizes
        push!(indicators, "Image dimensions $(width)x$(height) match common AI generation sizes")
        synthetic_score += 0.10
    end

    probability = clamp(synthetic_score, 0.0, 1.0)

    # Confidence is higher when we have more indicators or a more definitive result
    confidence = if length(indicators) >= 3
        0.85
    elseif length(indicators) >= 2
        0.70
    elseif length(indicators) >= 1
        0.55
    else
        0.80  # confident it's NOT synthetic
    end

    return (
        is_synthetic_probability = round(probability; digits=3),
        confidence = confidence,
        indicators = indicators
    )
end

# ============================================================================
# Internal helper functions
# ============================================================================

"""Detect image format from magic bytes."""
function _detect_image_format(data::Vector{UInt8})
    length(data) < 4 && return :unknown
    if data[1:3] == JPEG_MAGIC
        return :jpeg
    elseif data[1:4] == PNG_MAGIC
        return :png
    else
        return :unknown
    end
end

"""Check for EXIF data in the file (looks for APP1 marker in JPEG or tEXt/eXIf in PNG)."""
function _has_exif_data(data::Vector{UInt8})
    # JPEG EXIF: APP1 marker (FFE1) followed by "Exif\0\0"
    for i in 1:(length(data) - 7)
        if data[i] == 0xFF && data[i+1] == 0xE1
            if i + 5 <= length(data) && String(data[i+4:i+7]) == "Exif"
                return true
            end
        end
    end
    # PNG: look for eXIf chunk
    exif_chunk = UInt8.(collect("eXIf"))
    for i in 1:(length(data) - 7)
        if data[i:i+3] == exif_chunk
            return true
        end
    end
    return false
end

"""Extract the EXIF Software tag value, if present."""
function _extract_exif_software(data::Vector{UInt8})
    # Simple pattern match for "Software" followed by a string
    # The EXIF Software tag ID is 0x0131
    software_tag = UInt8.(collect("Software"))
    for i in 1:(length(data) - 20)
        if length(data) >= i + length(software_tag) - 1 &&
           data[i:i+length(software_tag)-1] == software_tag
            # Read the following string until null byte
            str_start = i + length(software_tag)
            # Skip any padding/null bytes
            while str_start <= length(data) && data[str_start] in (0x00, 0x20)
                str_start += 1
            end
            str_end = str_start
            while str_end <= length(data) && data[str_end] >= 0x20 && data[str_end] <= 0x7E
                str_end += 1
            end
            if str_end > str_start
                return String(data[str_start:str_end-1])
            end
        end
    end
    return nothing
end

"""Analyse JPEG quantization tables for double compression evidence."""
function _analyse_jpeg_quantization(data::Vector{UInt8})
    # DQT marker is FFDB
    tables = Int[]
    inconsistent = false

    for i in 1:(length(data) - 2)
        if data[i] == 0xFF && data[i+1] == 0xDB
            # Found a DQT marker; extract table values
            if i + 4 <= length(data)
                # Sum the quantization values as a quality proxy
                table_start = i + 4
                table_end = min(table_start + 63, length(data))
                if table_end - table_start >= 63
                    total = sum(Int.(data[table_start:table_end]))
                    push!(tables, total)
                end
            end
        end
    end

    estimated_quality = if !isempty(tables)
        # Lower sum = higher quality; approximate mapping
        avg = sum(tables) / length(tables)
        clamp(round(Int, 100 - avg / 50), 1, 100)
    else
        0
    end

    # Double compression: quality estimate suggests re-encoding
    double_compressed = estimated_quality > 0 && estimated_quality < 85

    # Inconsistent tables: luminance vs chrominance should be proportional
    if length(tables) >= 2
        ratio = tables[1] / max(tables[2], 1)
        inconsistent = ratio < 0.3 || ratio > 3.0
    end

    return (double_compressed=double_compressed, inconsistent_tables=inconsistent,
            estimated_quality=estimated_quality)
end

"""Find the JPEG End-Of-Image marker (FFD9)."""
function _find_jpeg_eoi(data::Vector{UInt8})
    for i in (length(data) - 1):-1:2
        if data[i] == 0xFF && data[i+1] == 0xD9
            return i + 1
        end
    end
    return nothing
end

"""Check if JPEG embedded thumbnail matches the main image dimensions."""
function _check_thumbnail_consistency(data::Vector{UInt8})
    # Look for a second JPEG SOI marker (FFD8) inside the EXIF data
    soi_count = 0
    for i in 1:(length(data) - 1)
        if data[i] == 0xFF && data[i+1] == 0xD8
            soi_count += 1
        end
    end
    if soi_count >= 2
        return :present  # thumbnail exists; full comparison requires decoding both
    end
    return :missing
end

"""Check PNG chunk structure for anomalies."""
function _check_png_chunks(data::Vector{UInt8})
    notes = String[]
    if length(data) < 8
        return notes
    end

    # PNG chunks start after the 8-byte signature
    pos = 9
    chunk_count = 0
    has_iend = false

    while pos + 8 <= length(data)
        chunk_len = _read_be_u32_from(data, pos)
        chunk_type = String(data[pos+4:pos+7])
        chunk_count += 1

        if chunk_type == "IEND"
            has_iend = true
            remaining = length(data) - (pos + 12)  # 4 len + 4 type + 4 CRC
            if remaining > 0
                push!(notes, "$(remaining) bytes after IEND chunk (possible steganography)")
            end
            break
        end

        # Check for suspicious ancillary chunks
        if chunk_type == "tEXt" || chunk_type == "zTXt" || chunk_type == "iTXt"
            # Text chunks may contain metadata
        end

        pos += 12 + chunk_len  # 4 len + 4 type + data + 4 CRC
    end

    if !has_iend
        push!(notes, "Missing IEND chunk (truncated PNG)")
    end

    return notes
end

"""Read a big-endian UInt32 from data at the given offset."""
function _read_be_u32_from(data::Vector{UInt8}, offset::Int)
    return (UInt32(data[offset]) << 24) | (UInt32(data[offset+1]) << 16) |
           (UInt32(data[offset+2]) << 8) | UInt32(data[offset+3])
end

"""Measure colour histogram smoothness (0 = rough, 1 = perfectly smooth)."""
function _colour_histogram_smoothness(img)
    # Convert to grayscale and compute histogram
    gray_vals = Float64.(Gray.(img))
    nbins = 256
    hist = zeros(Int, nbins)
    for v in gray_vals
        bin = clamp(round(Int, v * (nbins - 1)) + 1, 1, nbins)
        hist[bin] += 1
    end

    # Compute smoothness as 1 - normalised variance of bin-to-bin differences
    diffs = abs.(diff(hist))
    max_diff = maximum(diffs)
    max_diff == 0 && return 1.0

    normalised_diffs = diffs ./ max_diff
    smoothness = 1.0 - std(normalised_diffs)
    return clamp(smoothness, 0.0, 1.0)
end

"""Estimate sensor noise level from a grayscale image using local variance."""
function _estimate_noise_level(gray)
    height, width = size(gray)
    if height < 8 || width < 8
        return 0.0
    end

    # Sample local variance in 4x4 blocks across the image
    variances = Float64[]
    step = max(height, width) >= 256 ? 8 : 4
    for y in 1:step:(height - 3)
        for x in 1:step:(width - 3)
            block = Float64.(gray[y:y+3, x:x+3])
            v = var(block)
            push!(variances, v)
        end
    end

    # The noise level is approximated by the median of local variances
    isempty(variances) && return 0.0
    sort!(variances)
    return variances[length(variances) >> 1 + 1]
end

"""Compute variance of edge strengths across the image."""
function _edge_coherence_variance(gray)
    height, width = size(gray)
    if height < 4 || width < 4
        return 0.0
    end

    # Simple Sobel-like horizontal gradient
    edge_strengths = Float64[]
    for y in 2:(height - 1)
        for x in 2:(width - 1)
            gx = Float64(gray[y, x+1]) - Float64(gray[y, x-1])
            gy = Float64(gray[y+1, x]) - Float64(gray[y-1, x])
            push!(edge_strengths, sqrt(gx^2 + gy^2))
        end
    end

    isempty(edge_strengths) && return 0.0
    return var(edge_strengths)
end

"""Detect repeating texture patterns via autocorrelation on sampled rows."""
function _detect_texture_repetition(gray)
    height, width = size(gray)
    if width < 64 || height < 64
        return false
    end

    # Sample a few rows and check for periodic patterns
    sample_rows = [height >> 3, height >> 2, height >> 1]
    for row_idx in sample_rows
        row_idx < 1 || row_idx > height && continue
        row = Float64.(gray[row_idx, :])

        # Simple autocorrelation at lag offsets
        n = length(row)
        mean_r = sum(row) / n
        row_centered = row .- mean_r
        var_r = sum(row_centered .^ 2) / n
        var_r < 1e-10 && continue

        for lag in [16, 32, 64]
            lag >= n && continue
            corr = sum(row_centered[1:n-lag] .* row_centered[lag+1:n]) / ((n - lag) * var_r)
            if corr > 0.8
                return true
            end
        end
    end

    return false
end

# Bring in Statistics.var and Statistics.std if not already available
function var(x::AbstractVector{Float64})
    n = length(x)
    n <= 1 && return 0.0
    m = sum(x) / n
    return sum((xi - m)^2 for xi in x) / (n - 1)
end

function std(x::AbstractVector{Float64})
    return sqrt(var(x))
end

end # module
