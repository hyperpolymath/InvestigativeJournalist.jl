# TEST-NEEDS: InvestigativeJournalist.jl

## Current State

| Category | Count | Details |
|----------|-------|---------|
| **Source modules** | 19 | 1,525 lines |
| **Test files** | 1 | 488 lines, 222 @test/@testset |
| **Benchmarks** | 0 | None |
| **E2E tests** | 0 | None |

## What's Missing

### E2E Tests
- [ ] No end-to-end investigation pipeline test

### Aspect Tests
- [ ] **Security**: Investigation tool -- needs data handling security tests
- [ ] **Performance**: No benchmarks for data analysis throughput
- [ ] **Error handling**: No tests for corrupt data sources, API failures

### Benchmarks Needed
- [ ] Data source ingestion throughput
- [ ] Analysis pipeline latency

## FLAGGED ISSUES
- **222 tests for 19 modules = 11.7 tests/module** -- adequate
- **Single test file for 19 modules** -- should be split

## Priority: P2 (MEDIUM)

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage
