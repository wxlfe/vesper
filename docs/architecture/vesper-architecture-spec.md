# Vesper Architecture Specification

Vesper is a privacy-first prayer request and pastoral care platform for churches and small groups. It is designed to make encrypted prayer collaboration feel calm, understandable, and operationally simple.

## Foundational Principles

- End-to-end encrypted prayer requests
- Calm, emotionally safe user experience
- Modern church-friendly design language
- Simple operational overhead for churches and Leaders

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

Vesper targets iOS and Android through Flutter, with iOS as the first implementation validation target and Android close behind. Future web, macOS, or Windows clients require a clearly documented trust model, especially for browser-based clients.

Initial mobile app identifiers:

- App name: `Vesper`
- Bundle/package name: `dev.wxlfe.vesper`
- Initial version: `0.1.0`
- Firebase project: `vesper-47594`

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
- Firebase Cloud Messaging for generic notifications when notification features are enabled
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
- Group member: a user's role and status within a group. The canonical group roles are `leader` and `member`.
- Group key: symmetric key used to encrypt group-scoped sensitive content.
- Prayer request: encrypted content plus non-sensitive routing metadata and publishing status.
- Prayer update: encrypted follow-up, answered-prayer update, or private note.
- Invitation: controlled invite-code flow for joining a group and receiving an encrypted group key after Leader approval.

## Group Governance

Groups use two roles: `leader` and `member`. The group creator becomes a Leader automatically. Leaders can approve join requests, approve pending prayer requests when a group requires review, manage membership, and nominate Members to become Leaders.

Any active member may create or share a copyable invite code for their group. Using an invite code creates a join request rather than immediate membership. Leaders should see who requested access and, when known, which member invited them. Membership begins only after Leader approval and successful delivery of an encrypted group key.

Leader promotion is intentionally quiet and Leader-only. When a Leader nominates a Member for promotion, the nominee remains a Member for 24 hours and the pending promotion is visible only to current Leaders. Members, including the nominee, must not see the pending promotion, approvals, disputes, or cancellation state. If all current Leaders explicitly approve before the 24-hour window ends, the nominee becomes a Leader immediately. If no Leader disputes the promotion before the deadline, the nominee becomes a Leader automatically. If any Leader disputes it, the promotion is cancelled and the dispute remains visible to Leaders.

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

Group setup must include a request publishing option:

- Approve before publishing: member-created requests are visible only to the author and approving Leaders until approved.
- Publish immediately: member-created requests appear in the group feed by default after upload.

Group management should include invite codes, join requests, member roles, and Leader-only promotion review without making the group feel bureaucratic.

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

New request notifications should be sent only when a request is published to the group. Approval-required groups may notify approving Leaders that a request needs review, using generic copy only.

Avoid urgency, streaks, gamified loops, and addiction mechanics.

## Moderation Model

Because content is end-to-end encrypted, platform operators cannot inspect or centrally moderate prayer content. Moderation is primarily a Leader and church responsibility.

Groups may choose whether new requests require approval before being published. Approval happens inside the group's trust boundary: approving Leaders can decrypt pending requests on-device, while platform operators and Cloud Functions still cannot read request content. Groups that do not need pre-publication review may publish requests immediately by default.

Design implications:

- Reporting tools are limited by encryption boundaries.
- Group ownership and trusted administration are essential.
- Pending approval is a publishing state, not a server-side plaintext moderation workflow.
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
