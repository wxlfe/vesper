# Vesper

Vesper is a privacy-first prayer request and pastoral care platform for churches and small groups. The product is designed around end-to-end encrypted prayer requests, calm user experience, and simple operational overhead for church communities.

## Product Direction

Vesper should feel trustworthy, quiet, pastoral, modern, privacy-respecting, and emotionally lightweight. It should not feel corporate, gamified, social-media-like, surveillance-oriented, or driven by engagement mechanics.

Core goals:

- Help churches and small groups manage prayer requests securely.
- Keep prayer request content unreadable from Firebase Console.
- Support group-based prayer, follow-up, and care workflows.
- Preserve usability despite client-side encryption.
- Keep group governance simple with Leader and Member roles.

## Planned Stack

- Flutter for iOS and Android
- Firebase Authentication for identity
- Firestore for encrypted synchronization and metadata
- Cloud Functions for orchestration without plaintext access
- Firebase Cloud Messaging for generic notifications only when notification features are enabled
- Firebase App Check for abuse reduction

Initial implementation targets Firebase project `vesper-47594`, app name `Vesper`, bundle/package name `dev.wxlfe.vesper`, and version `0.1.0`. iOS is the first validation target, with Android close behind.

See [Architecture Specification](docs/architecture/vesper-architecture-spec.md) for the full system overview.

## Documentation

Architecture:

- [Architecture Specification](docs/architecture/vesper-architecture-spec.md)
- [Encryption Model](docs/architecture/encryption-model.md)
- [Firestore Schema](docs/architecture/firestore-schema.md)
- [Offline Sync](docs/architecture/offline-sync.md)

Design:

- [Design System](docs/design/design-system.md)
- [Motion Guidelines](docs/design/motion-guidelines.md)
- [Accessibility](docs/design/accessibility.md)

Product:

- [Roadmap](docs/product/roadmap.md)
- Feature specs should live in `docs/product/feature-specs/`

## Current Status

This repository now contains the initial Flutter/Firebase implementation scaffold for Phase 1 MVP validation. Current app code covers email authentication, public key registration, group creation, copyable invite codes, Leader-approved join requests, encrypted group-key delivery, encrypted prayer requests, request approval/status actions, follow-up reminders, Leader-only group settings changes, and basic encrypted-record offline viewing.

## Security Posture

Prayer request contents, private notes, follow-up notes, sensitive tags, attachment metadata, and content-derived summaries must be encrypted before leaving the device. Backend services must never receive plaintext prayer content, plaintext group keys, or user private keys.

Notifications must remain generic and must not include prayer request plaintext.
