---
version: 1.0
name: Numbering-quiet-minimal
status: canonical
description: "A quiet, premium puzzle UI built from off-white space, near-black type, low-saturation pastel cards, thin hairlines, and a fixed 7:3 landscape Bento layout. The puzzle and its primary action are always the visual focus."

principles:
  - purpose-first
  - one-primary-action-per-screen
  - content-over-decoration
  - border-over-elevation
  - low-saturation-surfaces
  - functional-color-only

colors:
  primary: "#171716"
  on-primary: "#ffffff"
  ink: "#171716"
  text-secondary: "#777570"
  app-background: "#faf9f6"
  surface: "#ffffff"
  surface-soft: "#f1f0eb"
  hairline: "rgba(23, 23, 22, 0.10)"
  hairline-soft: "rgba(23, 23, 22, 0.05)"
  block-lime: "#edf1e3"
  block-lilac: "#ede9f5"
  block-cream: "#f2ece2"
  block-pink: "#f3e9e7"
  block-mint: "#e8efe8"
  block-coral: "#f2e8e2"

typography:
  family: "system-ui, -apple-system, BlinkMacSystemFont, sans-serif"
  hero:
    fontSize: 32-40px
    fontWeight: 800
    lineHeight: 0.98-1.05
    letterSpacing: -1.6px
  screen-title:
    fontSize: 20-24px
    fontWeight: 800
    letterSpacing: -0.4px
  card-title:
    fontSize: 20-28px
    fontWeight: 800
    maxLines: 2
  body:
    fontSize: 14-16px
    fontWeight: 500-600
    lineHeight: 1.45
  label:
    fontSize: 10-12px
    fontWeight: 700-800
    textTransform: uppercase
    letterSpacing: 0.8-1.4px

layout:
  home:
    orientation: landscape
    scrolling: forbidden
    composition: "7:3 Bento"
    primary-column: 70%
    secondary-column: 30%
    secondary-stack-count: 2
    gap: 14px
    outer-padding: "clamp(22px, 5.5vw, 48px)"
    header-left: "NUMBERING only"
    header-right: [profile, settings]
  max-content-width: 960px
  minimum-touch-target: 44px

shape:
  card-radius: 24px
  control-radius: 14-16px
  pill-radius: 999px
  border-width: 1px
  border-color: hairline

elevation:
  cards: none
  buttons: none
  dialogs: none
  exception: "Light depth is allowed only on actively manipulated gameplay pieces."

motion:
  transition-duration: 150-220ms
  press-duration: 100ms
  press-scale: 0.96-0.98
  curve: easeOutCubic

rules:
  required:
    - "Use semantic tokens from lib/theme instead of screen-local color values."
    - "Keep one dominant tint per card and no more than three pastel card colors per screen."
    - "Keep the home screen entirely visible without scrolling."
    - "Use labels and whitespace before adding icons or illustrations."
    - "Preserve high-saturation colors for success, danger, time pressure, and puzzle blocks."
  forbidden:
    - gradients
    - glassmorphism
    - decorative-3d-art
    - background-grids
    - hard-shadows
    - decorative-glow
    - home-statistics-bar
    - home-leaderboard-list
    - brand-tagline-under-logo

validation:
  - flutter-analyze
  - flutter-test
  - no-overflow-at-844x390
  - no-overflow-at-667x375
  - no-home-scroll-view
---

# NUMBERING UI Rules

This file is the machine-readable canonical design contract. Human-readable rationale and examples live in [`docs/design_system.md`](docs/design_system.md). Game-specific exceptions live in [`docs/game_design_system.md`](docs/game_design_system.md).
