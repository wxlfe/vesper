# Agent Instructions

This repository is for Vesper, a privacy-first prayer request and pastoral care platform. Treat the documentation in `docs/` as the current product, architecture, security, and design source of truth.

## Start Here

Before making product or implementation decisions, read the relevant docs:

- `docs/architecture/vesper-architecture-spec.md` for the system overview
- `docs/architecture/encryption-model.md` for encryption requirements
- `docs/architecture/firestore-schema.md` for data model expectations
- `docs/architecture/offline-sync.md` for offline behavior
- `docs/design/design-system.md` for visual and interaction principles
- `docs/design/motion-guidelines.md` for animation guidance
- `docs/design/accessibility.md` for accessibility requirements
- `docs/product/roadmap.md` for product sequencing

## Product Principles

- Preserve end-to-end encryption for prayer content.
- Keep the experience calm, pastoral, quiet, and emotionally lightweight.
- Avoid social media mechanics such as public reactions, likes, streaks, viral feeds, and engagement loops.
- Prefer simple church-friendly workflows over complex enterprise assumptions unless the roadmap calls for them.
- Make privacy understandable without using fear-based cybersecurity language.

## Security Rules For Contributors

- Never store prayer request plaintext in Firestore.
- Never send prayer request plaintext through Cloud Functions, push notifications, logs, analytics, crash reports, or telemetry.
- Never store user private keys or plaintext group keys on the backend.
- Encrypt sensitive content on-device before persistence or upload.
- Treat Firebase Security Rules as access control only, not as the confidentiality boundary.
- Notifications must use generic language only.

Sensitive content includes request title, body, private notes, pastoral care notes, sensitive tags, private comments, attachment metadata, and content-derived summaries.

## Implementation Guidance

- The planned client stack is Flutter.
- Riverpod is the preferred state management approach unless a later decision changes this.
- Firebase is the planned backend platform.
- Keep application code structured around `lib/core`, `lib/features`, and `lib/shared` as described in the architecture spec.
- Place crypto responsibilities under `lib/core/crypto` when application code is introduced.
- Keep changes minimal and aligned with the documented roadmap.

## Design Guidance

- Follow the existing design system before introducing new visual language.
- Use generous spacing, restrained iconography, and minimal elevation.
- Respect WCAG AA contrast, platform text scaling, screen readers, reduced motion, and minimum `44x44` touch targets.
- Motion should clarify state changes and should not feel gamified or flashy.

## Documentation Guidance

- Update docs in the same change when behavior, architecture, schema, or product scope changes.
- Add detailed feature specs under `docs/product/feature-specs/` when a feature becomes ready for design or implementation.
- Keep `README.md` concise and use deeper docs for details.
