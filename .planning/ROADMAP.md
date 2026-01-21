# Roadmap: dotViewer

## Milestones

- [v1.0 Bug-Fix Release](milestones/v1.0-ROADMAP.md) — Phases 1-4 (shipped 2026-01-19)
- **[v1.1 Performance Overhaul](milestones/v1.1-performance-ROADMAP.md)** — Phases P1-P6 (IN PROGRESS - BLOCKING)
- v1.2 App Store Submission — Phases 6-12 (QUEUED)

## Completed Milestones

<details>
<summary>v1.0 Bug-Fix Release (Phases 1-4) — SHIPPED 2026-01-19</summary>

- [x] Phase 1: Foundation & UTI Fixes (3/3 plans) — completed 2026-01-15
- [x] Phase 2: UI Bug Fixes (3/3 plans) — completed 2026-01-16
- [x] Phase 3: Performance & Syntax Highlighting (2/2 plans) — completed 2026-01-19
- [x] Phase 4: App Store Preparation (1/1 plan) — completed 2026-01-19

</details>

<details>
<summary>v1.1 App Store Assets (Phase 5) — COMPLETED 2026-01-21</summary>

- [x] Phase 5: App Store Assets (1/1 plan) — completed 2026-01-21

</details>

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 1-4 | v1.0 | 9/9 | Complete | 2026-01-19 |
| 5 | v1.1 Assets | 1/1 | Complete | 2026-01-21 |
| P1 | v1.1 Performance | 0/1 | **NEXT** | - |
| P2 | v1.1 Performance | 0/1 | Pending | - |
| P3 | v1.1 Performance | 0/2 | Pending | - |
| P4 | v1.1 Performance | 0/2 | Pending | - |
| P5 | v1.1 Performance | 0/1 | Conditional | - |
| P6 | v1.1 Performance | 0/1 | Pending | - |
| 6-12 | v1.2 App Store | 0/? | Queued | - |

---

## v1.1 Performance Overhaul (BLOCKING - IN PROGRESS)

**Priority:** CRITICAL
**Goal:** Achieve <500ms highlighting for files up to 2000 lines
**Blocks:** App Store Submission

See [v1.1-performance-ROADMAP.md](milestones/v1.1-performance-ROADMAP.md) for full details.

### Phase P1: Diagnostics & Profiling
**Goal:** Understand where time is spent before optimizing
**Plans:** 1
**Status:** NEXT

- [ ] P1-01: Add timing instrumentation, create DIAGNOSTICS.md

### Phase P2: Quick Wins
**Goal:** Low-effort fixes (mappings, detection optimization)
**Depends on:** P1
**Plans:** 1

- [ ] P2-01: Add .plist mapping, Xcode UTIs, disable auto-detection

### Phase P3: Persistent Cache
**Goal:** Cache survives QuickLook XPC termination
**Depends on:** P2
**Plans:** 2

- [ ] P3-01: Create DiskCache with App Groups storage
- [ ] P3-02: Integrate cache, verify persistence

### Phase P4: Highlighter Evaluation
**Goal:** Data-driven highlighter decision
**Depends on:** P3
**Plans:** 2

- [ ] P4-01: Benchmark all highlighters (Fast, HighlightSwift, Highlightr)
- [ ] P4-02: Implement chosen solution

### Phase P5: Advanced Optimizations (CONDITIONAL)
**Goal:** Additional optimizations if P1-P4 don't meet targets
**Depends on:** P4
**Plans:** 1-3

- [ ] P5-01: Progressive rendering, WKWebView, or regex optimization

### Phase P6: Integration & Verification
**Goal:** Final verification before resuming App Store submission
**Depends on:** P4 or P5
**Plans:** 1

- [ ] P6-01: Comprehensive testing, human verification

---

## v1.2 App Store Submission (QUEUED)

**Blocked by:** v1.1 Performance Overhaul
**Resumes after:** P6 complete

### Phase 6: App Store Connect Setup
**Goal:** Create app record, configure pricing and availability
**Plans:** TBD

### Phase 7: Metadata & Description
**Goal:** Write app description, keywords, categories
**Plans:** TBD

### Phase 8: Privacy & Legal
**Goal:** Privacy policy, privacy practices declaration
**Plans:** TBD

### Phase 9: Code Signing & Notarization
**Goal:** Production certificates, notarization
**Plans:** TBD

### Phase 10: TestFlight Beta
**Goal:** Internal testing via TestFlight
**Plans:** TBD

### Phase 11: Final Build & Submission
**Goal:** Submit to App Store review
**Plans:** TBD

### Phase 12: Post-Submission
**Goal:** Monitor review, respond to feedback
**Plans:** TBD

---

## Key Dates

| Event | Date |
|-------|------|
| v1.0 Shipped | 2026-01-19 |
| Performance Issue Identified | 2026-01-21 |
| v1.1 Performance Milestone Created | 2026-01-21 |
| App Store Submission Target | TBD (after performance fix) |
