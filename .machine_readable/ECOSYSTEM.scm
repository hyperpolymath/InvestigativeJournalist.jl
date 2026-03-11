;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm for InvestigativeJournalist.jl
;; Media Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0")
  (name "InvestigativeJournalist.jl")
  (type "julia-package")
  (purpose "Structured evidence management for investigative reporting")
  (position-in-ecosystem
    (domain "journalism")
    (role "Evidence management and source protection for investigative workflows")
    (maturity "beta"))
  (related-projects
    ((name . "hyperpolymath ecosystem")
     (relationship . part-of)
     (nature . "Julia packages for interdisciplinary computing"))))
