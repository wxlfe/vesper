# Personal Prayer Routines

## Problem

Users need a private way to organize prayer around their own rhythms, user-supplied text, and requests from their groups. Vesper should support a simple daily prayer session as well as richer structures such as morning, evening, or historic-hour routines without shipping prayer-book content.

## Goals

- Let users create any number of scheduled prayer sessions.
- Let users name sessions and arrange routine sections however they choose.
- Support user-supplied sections.
- Include a request-feed section by default that dynamically inserts the viewing user's current group requests.
- Let users choose optional generic push reminders for prayer sessions.
- Sync routine structure across the user's trusted devices.
- Encrypt private routine content and personal prayers on-device.
- Support routine sharing where custom text is shared but request-feed contents are recipient-specific.
- Make the `Pray` tab the logged-in landing screen.
- Present routines first in a horizontal row of circular icons.
- Present the consolidated request feed below routines.
- Guide users through selected routines one full-screen step at a time.

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
- As a user, I can add simple sections to a routine.
- As a user, I can place my request feed anywhere in the routine.
- As a user, I can reorder routine sections.
- As a user, I can build one simple daily prayer session or many scheduled sessions.
- As a user, I can pray through a previously synced routine offline.
- As a user, I can share a routine with another user.
- As a recipient, I see the shared custom text, but the request-feed slot uses my own current request feed.
- As a user, I land on the `Pray` tab after logging in.
- As a user, I can see my routines in a horizontal circular-icon row.
- As a user, I can create a routine even if I already have routines.
- As a user, I can scroll my consolidated request feed below my routines.
- As a user, I can move through a selected routine step-by-step in full-screen vertical steps.
- As a user, I can join in prayer from a request step inside a routine.

## UX Notes

The `Pray` tab should feel like opening a personal prayer book. It is the signed-in landing tab and should show routines first, then the user's consolidated request feed.

Routines should appear in a horizontally scrollable row of circular icons with short labels, visually similar to the layout pattern of Instagram Stories but without social-story behavior. Do not include viewers, public activity rings, expiration, reactions, streaks, or engagement indicators. A `Create Routine` action must remain visible whether the user has no routines, one routine, or many routines.

Below the routine row, the consolidated request feed should show requests from all groups where the user is an active member. This feed remains private to the viewing user and assembled from group-scoped reads.

Routine sections should be easy to scan and easy to reorder without feeling like task management. The app may use manuscript-inspired section dividers, rubrics, and initials, but reading clarity comes first.

When a routine is selected, the Routine screen should guide the user through the routine one step at a time. A TikTok-like vertical full-screen scrolling list may be used as a layout pattern only: each routine step occupies the full screen, and the user moves vertically through the routine order. Avoid infinite feeds, autoplay, algorithmic recommendations, public metrics, or addictive motion.

Request steps inside a routine should preserve the existing `Join in prayer` action.

Vesper should not assume a specific prayer tradition in product copy. Users can build prayer offices, simple daily sessions, or any other structure themselves.

Reminder copy should be generic:

```text
Time for prayer
Your prayer session is ready
A prayer time is scheduled
```

## Routine Sections

Current section types:

- `custom_text`
- `request_feed`

A `request_feed` section stores placement and display configuration only. It does not store request IDs or copied request contents. When rendered, it resolves to the viewing user's current request organizer.

New routines include one `request_feed` section by default. If a user removes that request-feed section, the routine editor offers both `Section` and `Request feed`; otherwise, the add-section action creates another `Section` directly.

## Routine Sharing

When a user shares a routine, they share all sections of that routine.

Sharing behavior:

- Sections share their content and placement.
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

Custom routine section body content uses Quill Delta JSON as the canonical rich text format. The decrypted routine section payload stores `contentFormat: "quill_delta_json"` and `contentDeltaJson`; this rich text JSON is sensitive plaintext before encryption and must only be persisted inside encrypted payloads. Legacy plaintext routine section content may be converted into plain Quill Delta JSON on read.

## Security And Privacy

User-supplied prayer text, routine names, custom section text, personal prayer text, and private labels are sensitive content. Encrypt them on-device before persistence or upload.

Vesper must not send routine text, personal prayer content, or request content through Cloud Functions, notifications, logs, analytics, crash reports, or telemetry.

Reminder scheduling may require minimal metadata such as local time, timezone, and enabled state. Notification payloads must remain generic unless generated locally from decrypted data on the user's device.

## Offline Behavior

Previously synced prayer sessions, routine sections, personal prayers, and shared routines should be available offline. Request-feed sections should render cached requests the user can decrypt locally.

Routine edits and personal prayer edits may queue offline as encrypted pending writes. Do not store plaintext routine drafts in local queues.

## Acceptance Criteria

- Users can create, rename, archive, and delete prayer sessions.
- Users land on the `Pray` tab after login.
- Routines appear above the request feed in a horizontal circular-icon row.
- `Create Routine` remains visible regardless of routine count.
- Users can add, edit, remove, and reorder routine sections.
- New routines include a request-feed section by default.
- Users can add a request-feed section back to a routine after removing it.
- The request-feed section renders the viewing user's current eligible requests.
- The `Pray` tab shows a consolidated request feed below routines.
- Selecting a routine opens a full-screen step-by-step routine reader.
- Request steps preserve `Join in prayer`.
- Users can enable a generic reminder for a session.
- Private session and routine content syncs across the user's devices as encrypted payloads.
- Vesper does not ship prayer-book or office text.
- Shared routines include custom text content but not the sharer's request feed contents.
- Shared routine custom text remains encrypted in backend storage.

## Open Questions

- Should shared routines be direct-recipient only in Phase 2, or should share links be supported later?
- Should local notifications be allowed to show decrypted session names, or should all reminder copy remain generic for consistency?
- Should recurring schedules support complex recurrence rules in Phase 2 or stay time-of-day plus days-of-week?
