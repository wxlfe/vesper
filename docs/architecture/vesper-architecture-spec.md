# Vesper Architecture Specification

Vesper is a privacy-first prayer request and pastoral care platform for churches and small groups. It is designed to make encrypted prayer collaboration feel calm, understandable, and operationally simple.

## Foundational Principles

- End-to-end encrypted prayer requests
- Calm, emotionally safe user experience
- Modern church-friendly design language
- Simple operational overhead for churches and group leaders

Vesper should feel trustworthy, quiet, pastoral, modern, privacy-respecting, and emotionally lightweight. It should not feel corporate, gamified, social-media-like, surveillance-oriented, overly decorative, or aggressively religious.

## System Goals

- Allow churches and small groups to manage prayer requests securely.
- Ensure prayer request content is unreadable from Firebase Console.
- Support group-based prayer collaboration and pastoral follow-up.
- Preserve usability despite client-side encryption.
- Keep infrastructure lean enough for small teams to operate.

## Non-Goals

- Public social networking
- Public prayer feeds
- Ad-driven engagement
- Content recommendation algorithms
- Public discoverability of prayer requests
- Prayer content analytics

## Target Platforms

Phase 1 targets iOS and Android through Flutter. Phase 2 may add web, macOS, and Windows with a clearly documented trust model for browser-based clients.

## Technology Stack

### Client

- Flutter for mobile application development
- Riverpod as the preferred state management approach
- Platform secure storage through iOS Keychain and Android Keystore
- Local encrypted cache for offline viewing and queued writes

### Backend

- Firebase Authentication for identity
- Firestore for encrypted data synchronization and metadata
- Cloud Functions for orchestration that does not require plaintext access
- Firebase Cloud Messaging for generic notifications
- Firebase App Check to reduce abuse from untrusted clients

Cloud Functions must never possess plaintext prayer content, plaintext group keys, user private keys, or decrypted attachment contents.

## High-Level Architecture

```text
Flutter app
  |-- local secure storage
  |-- local encrypted cache
  |-- crypto services
  |-- Firebase SDKs

Firebase
  |-- Authentication
  |-- Firestore
  |-- Cloud Functions
  |-- Cloud Messaging
  |-- App Check
```

The client is responsible for encryption, decryption, key generation, key storage, and rendering decrypted content. Firebase stores encrypted payloads, membership metadata, notification routing metadata, and encrypted key material assigned to individual users.

## Project Structure

Recommended Flutter structure:

```text
/lib
  /core
    /theme
    /crypto
    /services
    /widgets
    /models

  /features
    /auth
    /groups
    /requests
    /profile
    /notifications

  /shared

  main.dart
```

Recommended crypto structure:

```text
/lib/core/crypto
  key_manager.dart
  encryption_service.dart
  secure_storage_service.dart
  group_key_service.dart
```

Responsibilities:

- `key_manager.dart`: user keypair generation and local key retrieval
- `encryption_service.dart`: payload encryption and decryption
- `secure_storage_service.dart`: Keychain and Keystore integration
- `group_key_service.dart`: group key lifecycle and member encryption workflows

## Security Boundaries

Prayer request contents must be unreadable from Firebase Console. Firebase Security Rules are required, but they are not sufficient because privileged Firebase access can still read stored documents. Sensitive content must be encrypted before it leaves the device.

Sensitive plaintext includes prayer request title, body, private notes, pastoral care notes, sensitive tags, private comments, attachment metadata, and any content-derived summary.

Non-sensitive metadata may include group IDs, document IDs, timestamps, coarse status, membership role, notification preference, and encrypted payload version.

## Core Domain Concepts

- User: authenticated person with a local private key and published public key.
- Group: church, small group, ministry team, or pastoral care circle.
- Group member: a user's role and status within a group.
- Group key: symmetric key used to encrypt group-scoped sensitive content.
- Prayer request: encrypted content plus non-sensitive routing metadata.
- Prayer update: encrypted follow-up, answered-prayer update, or private note.
- Invitation: controlled flow for joining a group and receiving an encrypted group key.

## Navigation Architecture

Recommended bottom navigation:

```text
home
groups
requests
profile
```

Alternative simplified model:

```text
inbox
groups
profile
```

## Primary Screens

### Home

Purpose:

- Emotional grounding
- Overview of active care
- Recent requests and follow-up reminders
- Answered prayers

The home screen should avoid dashboard clutter and avoid social-media-style urgency.

### Groups

Displays user groups, unread activity, and pending approvals. Group cards should be calm, lightweight, and easy to scan.

### Prayer Request Detail

Displays decrypted prayer content, author context, group, timestamps, and available care actions.

Actions:

- Prayed
- Follow up
- Resolve
- Archive

No reactions, likes, public counters, or public metrics should be shown.

## Notification Philosophy

Notifications should encourage prayer and care while remaining emotionally calm.

Allowed examples:

```text
new request in young adults
check in with sarah
three requests awaiting follow-up
```

Notifications must not contain plaintext prayer content.

Avoid urgency, streaks, gamified loops, and addiction mechanics.

## Moderation Model

Because content is end-to-end encrypted, platform operators cannot inspect or centrally moderate prayer content. Moderation is primarily a group-admin and church responsibility.

Design implications:

- Reporting tools are limited by encryption boundaries.
- Group ownership and trusted administration are essential.
- Abuse workflows should focus on membership controls, blocking, audit metadata, and church-owned escalation paths.

## Scalability Considerations

Firestore should be optimized for group-scoped reads, pagination, narrow indexes, and limited fanout. Avoid global feeds, cross-group queries, public discovery indexes, and content-derived search unless a future encrypted search model is explicitly designed.

## Related Documentation

- [Encryption Model](./encryption-model.md)
- [Firestore Schema](./firestore-schema.md)
- [Offline Sync](./offline-sync.md)
- [Design System](../design/design-system.md)
- [Motion Guidelines](../design/motion-guidelines.md)
- [Accessibility](../design/accessibility.md)
- [Product Roadmap](../product/roadmap.md)
