# Code Review Report: 2026-03-01

## Overview

Full codebase review of Aozora Reader iOS (SwiftUI + MVVM).
- **Total files reviewed**: 52 Swift files (~3,500 lines)
- **Issues identified**: 31
- **Issues fixed in this PR**: 11
- **Test results**: 48/48 passed
- **Lint**: 0 violations (SwiftLint + SwiftFormat)

## Issue Summary

### High Priority (Fixed)

| # | Issue | Severity | File | Fix |
|---|-------|----------|------|-----|
| 1 | Regex compiled on every validation call | High (Perf) | `SummaryQualityGuard.swift` | Pre-compile all regexes at `init()` |
| 2 | `@unchecked Sendable` without `@MainActor` | High (Safety) | `ReadingSettings.swift` | Added `@MainActor` annotation |
| 3 | Encoding detection tries full UTF-8 decode unnecessarily | High (Perf) | `TextFetchService.swift` | Check Content-Type header first, added EUC-JP support |
| 4 | Ruby regex compiled per parse call | High (Perf) | `AozoraTextParser.swift` | Pre-compile as `static let` |

### Medium Priority (Fixed)

| # | Issue | Severity | File | Fix |
|---|-------|----------|------|-----|
| 5 | Magic numbers in scoring algorithm | Medium (Maint) | `RecommendationService.swift` | Extracted to named constants with documentation |
| 6 | `FlowLayout` in `SearchScreen.swift` violates 1-type-per-file | Medium (Conv) | `SearchScreen.swift` | Extracted to `Sources/App/Components/FlowLayout.swift` |
| 7 | Hex colors duplicated between `ReadingTheme` and `VerticalPagedReaderView` | Medium (DRY) | `ReadingSettings.swift`, `VerticalPagedReaderView.swift` | Consolidated into `ReadingTheme` enum |
| 8 | Full object fetch for existence check | Medium (Perf) | `WorkDetailViewModel.swift` | Use `fetchCount` instead |
| 9 | Page jump dialog doesn't show current page | Medium (UX) | `ReaderScreen.swift` | Pre-populate with current page number |
| 10 | SwiftLint `for_where` violation | Medium (Lint) | `SummaryQualityGuard.swift` | Replaced `for` + `if` with `for ... where` |
| 11 | XcodeGen project out of sync with new file | Medium (Build) | `App.xcodeproj` | Regenerated project |

### Medium Priority (Not Fixed - Future Work)

| # | Issue | Severity | File | Reason |
|---|-------|----------|------|--------|
| 12 | No search debounce | Medium | `SearchScreen.swift` | UX design decision needed |
| 13 | Silent SwiftData failures | Medium | Multiple services | Requires error UI design |
| 14 | No pagination for search results | Medium | `CatalogService.swift` | Architecture decision needed |
| 15 | Complex View files (300+ lines) | Medium | `HomeScreen.swift`, `BookCoverView.swift`, `AuthorDetailScreen.swift` | Subviews already well-extracted |
| 16 | `TextFetchError.offline` unused | Medium | `TextFetchService.swift` | Requires network monitoring feature |

### Low Priority (Not Fixed - Tech Debt)

| # | Issue | Severity | Description |
|---|-------|----------|-------------|
| 17 | Low | No localization infrastructure (all Japanese strings hardcoded) |
| 18 | Low | Incomplete accessibility audit |
| 19 | Low | No UI tests |
| 20 | Low | Service test coverage missing (TextFetchService, CatalogService, etc.) |
| 21 | Low | Wikipedia API assumptions (no version check) |
| 22 | Low | No offline indicator UI |
| 23 | Low | Horizontal reader mode uses fragile GeometryReader preference keys |
| 24 | Low | `viewCount` naming ambiguous (total visits vs unique) |
| 25 | Low | Sparse algorithm documentation |
| 26 | Low | Single monolithic Xcode target |
| 27 | Low | No deep linking support |
| 28 | Low | Missing transaction boundaries for SwiftData |
| 29 | Low | Case-sensitive kana search (no hiragana/katakana normalization) |
| 30 | Low | WorkType classification relies on string matching |
| 31 | Low | CoverImageService cache never expires |

## Files Modified

| File | Change |
|------|--------|
| `Sources/App/Services/SummaryQualityGuard.swift` | Pre-compile regexes, `for_where` lint fix |
| `Sources/App/Models/ReadingSettings.swift` | Add `@MainActor`, consolidate hex colors |
| `Sources/App/Services/RecommendationService.swift` | Extract 8 magic numbers to named constants |
| `Sources/App/Components/FlowLayout.swift` | **New file** - extracted from SearchScreen |
| `Sources/Features/Search/View/SearchScreen.swift` | Remove embedded FlowLayout |
| `Sources/App/Services/TextFetchService.swift` | Improve encoding detection order |
| `Sources/Features/Reader/View/VerticalPagedReaderView.swift` | Remove duplicated hex extension |
| `Sources/Features/WorkDetail/ViewModel/WorkDetailViewModel.swift` | Use `fetchCount` |
| `Sources/Features/Reader/View/ReaderScreen.swift` | Pre-populate page jump |
| `Sources/App/Services/AozoraTextParser.swift` | Pre-compile ruby regex |

## Positive Findings

1. **Clean MVVM architecture** - View/ViewModel/Model/Service layers well-separated
2. **Modern Swift 6.2 patterns** - `@Observable`, `@State`, `@Bindable` used correctly
3. **Good Swift Concurrency** - `async/await`, actors, `@MainActor` properly applied
4. **Comprehensive tests** - 48 tests covering core logic (HomeViewModel, RecommendationService, SummaryQualityGuard, ReadingTimeEstimator)
5. **Strong design system** - CoverDesignPreset with genre-specific palettes
6. **Accessibility considered** - Labels and hints on key UI elements

## Recommendations for Next Steps

1. **Search debounce**: Add `Task` cancellation or debounce timer to prevent excessive searches
2. **Error UI**: Design and implement `ContentUnavailableView` for service failures
3. **Network monitoring**: Use `NWPathMonitor` for offline detection
4. **Test coverage**: Add service-layer tests with protocol-based mocks
5. **Localization**: Extract strings to `Localizable.strings` for i18n readiness
