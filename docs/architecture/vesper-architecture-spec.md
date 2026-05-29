# Vesper Architecture Specification

Vesper is a privacy-first prayer request and personal prayer-routine platform for churches, small groups, and individual prayer. It is designed to make encrypted prayer collaboration feel calm, readable, and operationally simple.

## Foundational Principles

- End-to-end encrypted prayer requests
- User-private personal prayer routines
- Calm, emotionally safe user experience
- Global illuminated manuscript visual language
- Simple operational overhead for churches and Leaders

Vesper should feel trustworthy, quiet, pastoral, prayerful, manuscript-inspired, privacy-respecting, and emotionally lightweight. It should not feel corporate, gamified, social-media-like, surveillance-oriented, visually cluttered, or aggressively religious.

## System Goals

- Allow churches and small groups to manage prayer requests securely.
- Let users build scheduled personal prayer routines from user-supplied content.
- Let users place their consolidated request feed inside a prayer routine at a point of their choosing.
- Ensure prayer request content, personal prayers, and routine custom text are unreadable from Firebase Console.
- Support group-based prayer collaboration and pastoral follow-up without heavy administration.
- Preserve usability despite client-side encryption.
- Keep infrastructure lean enough for small teams to operate.

## Non-Goals

- Public social networking
- Public prayer feeds
- Ad-driven engagement
- Content recommendation algorithms
- Public discoverability of prayer requests
- Prayer content analytics
- Shipping prayer-book, lectionary, or denominational office text as built-in app content
- Custom group role matrices or enterprise administration in the MVP

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

Cloud Functions must never possess plaintext prayer content, plaintext personal prayers, plaintext routine custom text, plaintext group keys, user private keys, or decrypted attachment contents.

## High-Level Architecture

```text
Flutter app
  |-- local secure storage
  |-- local encrypted cache
  |-- crypto services
  |-- prayer routine builder
  |-- Firebase SDKs

Firebase
  |-- Authentication
  |-- Firestore
  |-- Cloud Functions
  |-- Cloud Messaging
  |-- App Check
```

The client is responsible for encryption, decryption, key generation, key storage, and rendering decrypted content. Firebase stores encrypted payloads, membership metadata, notification routing metadata, encrypted key material assigned to individual users, and minimal scheduling metadata needed for reminders.

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
    /prayer
    /prayer_book
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
  user_content_key_service.dart
```

Responsibilities:

- `key_manager.dart`: user keypair generation and local key retrieval
- `encryption_service.dart`: payload encryption and decryption
- `secure_storage_service.dart`: Keychain and Keystore integration
- `group_key_service.dart`: group key lifecycle and member encryption workflows
- `user_content_key_service.dart`: user-private key lifecycle for personal prayers and routines

## Security Boundaries

Prayer request contents, personal prayer contents, private routine text, custom routine sections, and pastoral care notes must be unreadable from Firebase Console. Firebase Security Rules are required, but they are not sufficient because privileged Firebase access can still read stored documents. Sensitive content must be encrypted before it leaves the device.

Sensitive plaintext includes prayer request title, body, personal prayer text, private routine names, custom routine section text, private notes, pastoral care notes, sensitive tags, private comments, attachment metadata, and any content-derived summary.

Non-sensitive metadata may include group IDs, document IDs, timestamps, coarse status, membership role, notification preference, encrypted payload version, key version, algorithm identifier, and minimal reminder trigger metadata.

## Core Domain Concepts

- User: authenticated person with a local private key and published public key.
- Group: church, small group, ministry team, or pastoral care circle.
- Group member: a user's role and status within a group. The canonical group roles are `leader` and `member`.
- Group key: symmetric key used to encrypt group-scoped sensitive content.
- User content key: user-private key material used to encrypt personal prayers and private routine content for that user across trusted devices.
- Prayer request: encrypted group-scoped content plus non-sensitive routing metadata and status.
- Prayer update: encrypted follow-up, answered-prayer update, or private note.
- Invitation: controlled invite-code flow for joining a group and receiving an encrypted group key after Leader approval.
- Prayer session: user-defined scheduled prayer time, such as a morning routine, evening routine, or any custom prayer session.
- Prayer routine: ordered structure inside a session.
- Routine section: an ordered item in a routine, such as custom text, heading, silence, or a request-feed slot.
- Personal prayer: user-supplied encrypted prayer content private to the user unless intentionally shared as part of a routine.
- Request-feed slot: a routine section that dynamically inserts the viewing user's current request feed.
- Shared routine: a user-shared routine structure including custom text sections and request-feed slot placement, but not the sharer's actual request feed contents.

## Prayer Routines

Vesper should let users define as many scheduled prayer sessions as they want. One user may create a single daily prayer session; another may create morning, midday, evening, compline, or all historic hours. Vesper should not ship prayer-book or office text. All prayer text and routine content is user-supplied.

Each prayer session may include:

- User-defined name
- Optional scheduled reminder time
- Ordered routine sections
- Custom text sections supplied by the user
- A request-feed section placed wherever the user chooses
- Future section types such as silence, reading placeholder, or checklist

Private prayer sessions and custom text sections are encrypted on-device for the owning user and synced across that user's trusted devices. If session names or routine section labels reveal sensitive spiritual habits, they should be encrypted with the rest of the routine content.

Scheduled reminders must use generic push notification content. Backend-triggered notifications must not include prayer text, request text, routine text, or content-derived summaries. If a client can generate local notifications from decrypted local data, it may display locally available session names according to platform constraints and user settings.

## Consolidated Request Organizer

The user's request feed is a private organizer assembled from groups where the user is an active member. It is not a public feed, global feed, recommendation system, or engagement mechanism.

Implementation guidance:

- Fetch requests through group-scoped queries.
- Decrypt only on-device.
- Consolidate eligible requests client-side for the viewing user.
- Respect group membership, removal, key availability, status, and local cache retention.
- Avoid backend global feeds, cross-group request indexes, and content-derived ranking.

The request-feed slot in a routine should render the viewing user's own current requests. When a shared routine contains a request-feed slot, only the slot placement and configuration are shared; request contents are always resolved from the recipient's own groups.

## Shared Routines

When a user shares a routine, they share all sections of that routine.

Shared routine behavior:

- Custom text sections are shared with their content and placement.
- Heading, silence, and other structural sections are shared with their placement.
- Request-feed sections are shared only as dynamic slots.
- The sharer's actual group requests, personal request feed, and request IDs are never copied into the shared routine.
- The recipient's request-feed slot is populated from the recipient's own current request feed.

Shared routine content should be encrypted for intended recipients or transported through the app's encrypted sharing model. Sharing custom text is an intentional disclosure to recipients, but it must not become backend-readable plaintext.

## Group Governance

Groups use two roles: `leader` and `member`. The group creator becomes a Leader automatically. The MVP should keep group administration simple and focused on membership and trust.

Leader capabilities:

- Approve join requests
- Create and disable invite codes
- Promote a Member to Leader
- Demote another Leader when at least one Leader remains
- Remove a Member or Leader when at least one Leader remains
- Remove or archive inappropriate requests
- Review member reports

Member capabilities:

- Create encrypted prayer requests
- Create invite codes when group settings allow member invites
- Report requests for Leader review
- Mark other people's requests as prayed for
- Manage their own requests

Administrative rules:

- Member-created requests publish immediately to the group.
- Group-level approval before publishing is not part of the MVP.
- Last-Leader removal or demotion is prohibited.
- Promotion, demotion, and removal require confirmation.
- Member removal should explain that the member will lose access to future requests.
- Key rotation after member removal should happen quietly in the background.
- Administrative actions create metadata-only audit events.

Avoid custom roles, permission matrices, 24-hour dispute windows, multi-Leader consensus flows, and publishing-policy configuration unless a future roadmap phase reintroduces them for larger organizations.

## Navigation Architecture

Recommended bottom navigation:

```text
prayer
groups
prayer book
profile
```

The primary tab should be the user's prayer home, centered on the next scheduled prayer session and the user's private prayer routine.

## Primary Screens

### Prayer Home

Purpose:

- Open the user's next scheduled prayer session
- Provide calm access to prayer routines and the prayer book
- Show request-feed context only where it supports the user's routine
- Provide a FAB for creating a prayer request

The prayer home should avoid dashboard clutter and social-media-style urgency.

### Request Composer

The prayer request composer opens from the home FAB and lets the user choose the groups that should receive the request.

Composer requirements:

- Show active groups where the user is a member.
- Provide a checkbox for each eligible group.
- Provide a `Select All` option.
- Show clear selected-count feedback.
- Require at least one selected group before submission.
- Make the audience clear before upload.

Submitting to multiple groups creates separate prayer request records, one per selected group. Each record must be encrypted on-device with that group's active key. The backend must not receive plaintext request content or a plaintext content-derived summary.

### Prayer Session

Displays a user-defined routine as a calm reading flow. A request-feed section inserts the user's available group requests where the user placed that section. The session should support resuming, skipping optional sections, and reading at large text sizes without turning prayer into a completion game.

### Prayer Book

Stores user-supplied personal prayers and routine text. Vesper should not include built-in prayer-book text. Personal prayers are encrypted for the owning user unless intentionally shared inside a shared routine.

### Groups

Displays pinned groups, user groups, and calm group context. Group cards should be lightweight and easy to scan. Long-pressing a group row may open a menu with secondary actions such as `Pin` or `Unpin`, `Share`, and `Leave` without replacing the primary tap target. Pinned groups are a local preference and should not affect membership or visibility.

Group management should include invite codes, join requests, member roles, member removal, and metadata-only admin history without making the group feel bureaucratic.

### Profile

The Profile screen should be available from the home header. It should let the user manage their display name, review their own prayer requests across groups, and sign out from a low-emphasis logout button near the bottom of the screen.

### Prayer Request Detail

Displays decrypted prayer content, author context, group, timestamps, and available care actions.

Actions:

- Double-tap to mark someone else's request as prayed for
- Update, for the request author, inside the overflow menu
- Remove, for the request author, inside the overflow menu
- Answered, for the request author inside the overflow menu, or as a Leader action on another user's request
- Report, for members viewing another person's request
- Remove or archive, for Leaders when appropriate

Request cards should support multiple requests in a scrollable group detail view without clipping long request lists.

No reactions, likes, public counters, or public metrics should be shown.

## Notification Philosophy

Notifications should encourage prayer and care while remaining emotionally calm.

Allowed examples:

```text
time for prayer
your prayer session is ready
new request in your group
check in with someone today
three requests awaiting follow-up
```

Notifications must not contain plaintext prayer content, personal prayer content, routine custom text, request summaries, or content-derived hints.

Avoid urgency, streaks, gamified loops, and addiction mechanics.

## Moderation Model

Because content is end-to-end encrypted, platform operators cannot inspect or centrally moderate prayer content. Moderation is primarily a Leader and church responsibility.

Groups use a simple publish-immediately model. Members can report a request using metadata-only report records, and Leaders who can decrypt group content on-device may decide whether to archive or remove it. Platform operators and Cloud Functions still cannot read request content.

Design implications:

- Reporting tools are limited by encryption boundaries.
- Group ownership and trusted administration are essential.
- Abuse workflows should focus on membership controls, blocking, audit metadata, and church-owned escalation paths.
- Avoid approval queues and administrative bureaucracy in the MVP.

## Scalability Considerations

Firestore should be optimized for group-scoped reads, pagination, narrow indexes, and limited fanout. Avoid global backend feeds, cross-group request queries, public discovery indexes, and content-derived search unless a future encrypted search model is explicitly designed.

The consolidated request organizer should be assembled client-side from active memberships, group-scoped request queries, local cache, and decrypted content available to the user.

## Related Documentation

- [Encryption Model](./encryption-model.md)
- [Firestore Schema](./firestore-schema.md)
- [Offline Sync](./offline-sync.md)
- [Design System](../design/design-system.md)
- [Motion Guidelines](../design/motion-guidelines.md)
- [Accessibility](../design/accessibility.md)
- [Product Roadmap](../product/roadmap.md)
