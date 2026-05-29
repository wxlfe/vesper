# Personal Prayer Routines

## Problem

Users need a private way to organize prayer around their own rhythms, user-supplied text, and requests from their groups. Vesper should support a simple daily prayer session as well as richer structures such as morning, evening, or historic-hour routines without shipping prayer-book content.

## Goals

- Let users create any number of scheduled prayer sessions.
- Let users name sessions and arrange routine sections however they choose.
- Support user-supplied custom text sections.
- Support a request-feed section that dynamically inserts the viewing user's current group requests.
- Let users choose optional generic push reminders for prayer sessions.
- Sync routine structure across the user's trusted devices.
- Encrypt private routine content and personal prayers on-device.
- Support routine sharing where custom text is shared but request-feed contents are recipient-specific.

## Non-Goals

- Shipping 2019 Book of Common Prayer text or any other prayer-book content.
- Shipping lectionary text or denominational office text as built-in app content.
- Public routine discovery in the MVP.
- Social completion tracking, streaks, or public prayer metrics.
- Backend-readable personal prayer or routine content.

## User Stories

- As a user, I can create a prayer session named in my own words.
- As a user, I can schedule a prayer session for a time I choose.
- As a user, I can enable or disable a generic reminder for each session.
- As a user, I can add custom text sections to a routine.
- As a user, I can place my request feed anywhere in the routine.
- As a user, I can reorder routine sections.
- As a user, I can build one simple daily prayer session or many scheduled sessions.
- As a user, I can pray through a previously synced routine offline.
- As a user, I can share a routine with another user.
- As a recipient, I see the shared custom text, but the request-feed slot uses my own current request feed.

## UX Notes

The primary Prayer home should feel like opening a personal prayer book. It should emphasize the next scheduled session and provide calm access to other sessions and the prayer book.

Routine sections should be easy to scan and easy to reorder without feeling like task management. The app may use manuscript-inspired section dividers, rubrics, and initials, but reading clarity comes first.

Vesper should not assume a specific prayer tradition in product copy. Users can build prayer offices, simple daily sessions, or any other structure themselves.

Reminder copy should be generic:

```text
Time for prayer
Your prayer session is ready
A prayer time is scheduled
```

## Routine Sections

Initial section types:

- `custom_text`
- `request_feed`
- `heading`
- `silence`
- `reading_placeholder`

A `request_feed` section stores placement and display configuration only. It does not store request IDs or copied request contents. When rendered, it resolves to the viewing user's current request organizer.

## Routine Sharing

When a user shares a routine, they share all sections of that routine.

Sharing behavior:

- Custom text sections share their content and placement.
- Heading, silence, and placeholder sections share their content/configuration and placement.
- Request-feed sections share placement and configuration only.
- The sharer's actual request feed, group request IDs, group request content, and group-derived summaries are never shared.
- Recipients populate request-feed sections with their own current request feed.

Shared routine custom text is intentionally disclosed to recipients, but must still be encrypted in Firestore and in local storage.

## Data Model

Use the canonical collections in [Firestore Schema](../../architecture/firestore-schema.md):

- `prayer_sessions` for user-specific scheduled sessions and encrypted session metadata.
- `routine_sections` for encrypted ordered private routine sections.
- `personal_prayers` for encrypted user-private prayer book entries.
- `shared_routines` for encrypted shared routine metadata.
- `shared_routine_sections` for encrypted shared section content and placement.

Routine section ordering should use stable sort keys so offline edits can preserve all sections where possible.

## Security And Privacy

User-supplied prayer text, routine names, custom section text, personal prayer text, and private labels are sensitive content. Encrypt them on-device before persistence or upload.

Vesper must not send routine text, personal prayer content, or request content through Cloud Functions, notifications, logs, analytics, crash reports, or telemetry.

Reminder scheduling may require minimal metadata such as local time, timezone, and enabled state. Notification payloads must remain generic unless generated locally from decrypted data on the user's device.

## Offline Behavior

Previously synced prayer sessions, routine sections, personal prayers, and shared routines should be available offline. Request-feed sections should render cached requests the user can decrypt locally.

Routine edits and personal prayer edits may queue offline as encrypted pending writes. Do not store plaintext routine drafts in local queues.

## Acceptance Criteria

- Users can create, rename, archive, and delete prayer sessions.
- Users can add, edit, remove, and reorder routine sections.
- Users can add a request-feed section to a routine.
- The request-feed section renders the viewing user's current eligible requests.
- Users can enable a generic reminder for a session.
- Private session and routine content syncs across the user's devices as encrypted payloads.
- Vesper does not ship prayer-book or office text.
- Shared routines include custom text content but not the sharer's request feed contents.
- Shared routine custom text remains encrypted in backend storage.

## Open Questions

- Should shared routines be direct-recipient only in Phase 2, or should share links be supported later?
- Should local notifications be allowed to show decrypted session names, or should all reminder copy remain generic for consistency?
- Should recurring schedules support complex recurrence rules in Phase 2 or stay time-of-day plus days-of-week?
