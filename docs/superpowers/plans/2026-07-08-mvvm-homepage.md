# MVVM Homepage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the SwiftUI app to a lightweight MVVM structure and add a 4-tab homepage after mock login.

**Architecture:** Use one `@Observable` view model per feature screen. Keep model structs and design tokens reusable, and let `ContentView` own the app-level authenticated state.

**Tech Stack:** SwiftUI, Observation, async/await, SF Symbols, Xcode iOS target.

## Global Constraints

- Use native SwiftUI.
- Use RTD design colors and Bahasa Indonesia copy from `design.md`.
- Keep auth mock-only.
- Add 4 tabs: Foto Tanaman, Radar Feed, Lahan, Profil.
- No new dependencies.

---

### Task 1: MVVM Structure and Shared Models

**Files:**
- Modify: `RadarTaniMobile/ContentView.swift`
- Create: shared design, model, auth, home, tab feature files under `RadarTaniMobile/`.

**Interfaces:**
- Produces: `ContentView`, `LoginView`, `HomeTabView`, `Farm`, `RadarReport`, feature view models.

- [x] **Step 1: Add shared design and models**
- [x] **Step 2: Move login state into `LoginViewModel`**
- [x] **Step 3: Add `HomeTabView` with four tabs**
- [x] **Step 4: Add mock feature screens and data**
- [x] **Step 5: Verify build**

Run: `xcodebuild -project RadarTaniMobile.xcodeproj -scheme RadarTaniMobile -destination 'generic/platform=iOS Simulator' build`

Expected: `BUILD SUCCEEDED`

---

## Self-Review

- Spec coverage: MVVM restructure, homepage tabs, login transition, mock data, logout covered.
- Placeholder scan: no placeholders remain.
- Type consistency: all named files and types are defined by this plan.
