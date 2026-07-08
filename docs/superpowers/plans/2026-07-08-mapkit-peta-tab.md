# MapKit Peta Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `Peta` tab that displays mock Radar Feed reports on a SwiftUI MapKit map.

**Architecture:** Extend the existing tab architecture with a `HomeTab.map` case and `RadarMapView`. Keep report coordinate data in `RadarMapViewModel` using mock data only.

**Tech Stack:** SwiftUI, MapKit, Observation, existing RTD design system.

## Global Constraints

- Use static mock coordinates; do not request user location permission.
- Keep existing login and homepage behavior unchanged.
- Use RTD category colors for map annotations.
- Verify with `xcodebuild`.

---

### Task 1: Add Map Tab

**Files:**
- Modify: `RadarTaniMobile/Features/Home/Views/MainTabView.swift`
- Modify: `RadarTaniMobile/Features/Map/ViewModels/RadarMapViewModel.swift`
- Modify: `RadarTaniMobile/Features/Map/Views/RadarMapView.swift`
- Modify: `RadarTaniMobile/Features/Map/Components/MapLegendView.swift`
- Modify: `RadarTaniMobile/Features/Map/Components/ReportMapAnnotation.swift`

**Interfaces:**
- Produces: `HomeTab.map`, `RadarMapReport`, selectable MapKit annotations.

- [x] Add `Peta` tab after `Radar Feed`.
- [x] Add mock map report data with coordinates.
- [x] Render MapKit map with selectable custom annotations.
- [x] Show selected report summary card and category legend.
- [x] Build with Xcode.

---

## Self-Review

- Spec coverage: `Peta` tab, MapKit map, mock pins, legend, selected report summary covered.
- Placeholder scan: no placeholders in implemented map flow.
- Type consistency: `RadarMapReport` and selection IDs are consistent across view model and view.
