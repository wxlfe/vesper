# Firestore Schema

Firestore stores encrypted prayer data, encrypted personal routine data, membership metadata, notification routing data, and operational state. Sensitive prayer content must be encrypted before it is written.

## Collection Overview

```text
users/{userId}
groups/{groupId}
group_members/{membershipId}
group_keys/{groupKeyId}
invite_codes/{inviteCodeId}
join_requests/{joinRequestId}
prayer_requests/{requestId}
request_reports/{reportId}
prayer_updates/{updateId}
prayer_actions/{actionId}
prayer_sessions/{sessionId}
routine_sections/{sectionId}
personal_prayers/{personalPrayerId}
shared_routines/{sharedRoutineId}
shared_routine_sections/{sectionId}
notifications/{notificationId}
devices/{deviceId}
audit_events/{eventId}
```

Use deterministic composite IDs where they reduce duplication and simplify rules. For example, `group_members/{groupId_userId}` and `group_keys/{groupId_userId_keyVersion}`.

## Sensitive Content Rules

Never store sensitive plaintext in Firestore. Sensitive plaintext includes prayer request title, body, personal prayer text, custom routine text, private routine names, pastoral notes, sensitive tags, private comments, attachment metadata, and content-derived summaries.

Routine sharing intentionally discloses selected custom text to recipients, but shared custom text still must not be backend-readable plaintext. Encrypt shared routine content for intended recipients or use an app-level encrypted sharing model.

## `users`

Stores user profile and public cryptographic identity.

```json
{
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "publicKey": "base64",
  "publicKeyAlgorithm": "x25519",
  "createdAt": "timestamp",
  "lastActiveAt": "timestamp",
  "notificationPreferences": {
    "pushEnabled": true,
    "emailEnabled": false
  }
}
```

`displayName` is non-sensitive profile metadata used for member lists, Leader-facing join request review, admin history, and prayer request attribution inside groups. Do not copy display names into encrypted prayer payloads or use them in notification copy that could reveal request context.

Do not store private keys, recovery phrases, plaintext user content keys, plaintext group keys, or plaintext pastoral notes.

## `groups`

Stores group-level metadata that is acceptable for backend access.

```json
{
  "name": "Young Adults",
  "description": "Sunday evening group",
  "createdBy": "userId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "memberCount": 24,
  "activeKeyVersion": 3,
  "settings": {
    "allowMemberInvites": true
  }
}
```

Member-created requests publish immediately as `active`. Group-level Leader approval before publication is not part of the MVP.

`settings.allowMemberInvites` controls whether Members may create invite codes. The default product behavior is that active Members may invite, but invite codes create join requests rather than granting immediate access.

No sensitive prayer content should be stored here.

## `group_members`

Stores user membership within a group.

```json
{
  "groupId": "groupId",
  "userId": "userId",
  "role": "member",
  "joinedAt": "timestamp",
  "invitedBy": "userId",
  "status": "active"
}
```

Allowed roles:

- `leader`
- `member`

Allowed statuses:

- `pending`
- `active`
- `removed`
- `blocked`

Any Leader may promote, demote, or remove members, but the last active Leader cannot be demoted or removed. Access-changing actions require confirmation and create metadata-only audit events.

## `group_keys`

Stores one encrypted group key per member per key version.

```json
{
  "groupId": "groupId",
  "userId": "userId",
  "keyVersion": 3,
  "encryptedGroupKey": "base64",
  "nonce": "base64",
  "ephemeralPublicKey": "base64",
  "algorithm": "x25519-xchacha20-poly1305",
  "createdAt": "timestamp",
  "createdBy": "userId",
  "status": "active"
}
```

A user may only read their own `group_keys` documents. When a member is removed, future group content should use a rotated key version. Key rotation after removal should happen quietly in the background.

## `invite_codes`

Stores copyable invite-code metadata. Invite codes do not grant membership directly and must not contain prayer content.

```json
{
  "groupId": "groupId",
  "codeHash": "sha256-base64",
  "createdBy": "userId",
  "createdAt": "timestamp",
  "expiresAt": "timestamp",
  "status": "active",
  "useCount": 3,
  "maxUses": null
}
```

Allowed statuses:

- `active`
- `disabled`
- `expired`

The plaintext invite code should be shown only at creation or user entry time. Store a hash for lookup and validation where practical. Any active group member may create an invite code when group settings allow member invites.

## `join_requests`

Stores requests to join a group after a user enters an invite code.

```json
{
  "groupId": "groupId",
  "requestedBy": "userId",
  "invitedBy": "userId",
  "inviteCodeId": "inviteCodeId",
  "status": "pending",
  "createdAt": "timestamp",
  "decidedAt": null,
  "decidedBy": null
}
```

Allowed statuses:

- `pending`
- `approved`
- `rejected`
- `cancelled`

Leaders may read pending join requests for their groups. Approving a join request creates or activates the membership and requires a Leader device or trusted client flow to encrypt the active group key for the requester.

## `prayer_requests`

Stores one canonical encrypted request payload plus non-sensitive owner metadata. Requests are user-created first and may remain private to the creator or be shared to one or more groups through `request_shares`.

```json
{
  "createdBy": "userId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "status": "active",
  "anonymous": false,
  "keyVersion": 3,
  "payloadVersion": 2,
  "algorithm": "xchacha20-poly1305",
  "ciphertext": "base64",
  "nonce": "base64",
  "metadata": {
    "hasFollowup": true,
    "hasReminder": false,
    "followUpAt": "timestamp",
    "updateCount": 2
  }
}
```

Encrypted payload contains title, body, request rich text body, private notes, sensitive tags, care details, and any content-derived summary. Request body rich text uses Quill Delta JSON as the canonical body format while retaining an encrypted plaintext `body` fallback for compatibility:

```json
{
  "title": "Please pray",
  "body": "Private request body",
  "bodyFormat": "quill_delta_json",
  "bodyDeltaJson": "[{\"insert\":\"Private request body\\n\"}]"
}
```

`body`, `bodyFormat`, and `bodyDeltaJson` are sensitive plaintext before encryption and must never be stored in Firestore outside the encrypted payload.

Allowed statuses:

- `active`
- `answered`
- `resolved`
- `archived`
- `deleted`

The default personal feed shows the current user's non-deleted requests: `active`, `answered`, `resolved`, and `archived`. Group feeds are assembled from `request_shares`, then each canonical request is decrypted through the viewer's `request_key_grants` document found by `requestId` and `userId`. `answered`, `resolved`, and `archived` requests remain stored statuses but do not appear in the default group feed unless the product explicitly adds those filters.

Request authors may manage their own canonical requests after creation. Updating a request must re-encrypt the title, plaintext body fallback, and rich text body on-device before writing replacement ciphertext. Removing a request should transition it to `deleted` rather than deleting the document directly. Authors may also mark their own requests as `answered`.

## `request_shares`

Stores metadata-only group visibility for canonical requests.

```json
{
  "requestId": "requestId",
  "groupId": "groupId",
  "sharedBy": "userId",
  "sharedAt": "timestamp",
  "status": "active",
  "removedAt": null,
  "removedBy": null
}
```

Allowed statuses:

- `active`
- `removed`
- `deleted`

Leaders removing a request from a group update only that group's share record. This does not delete the canonical request, remove other group shares, or imply cryptographic revocation from devices that already received a request key grant.

## `request_key_grants`

Stores one encrypted request content key per authorized user per request.

```json
{
  "requestId": "requestId",
  "userId": "userId",
  "grantedBy": "userId",
  "grantedViaGroupId": "groupId-or-null",
  "createdAt": "timestamp",
  "encryptedGroupKey": "base64",
  "nonce": "base64",
  "ephemeralPublicKey": "base64",
  "algorithm": "x25519-xchacha20-poly1305"
}
```

Despite the field name `encryptedGroupKey`, the encrypted value is a request content key. The existing wrapping format is reused so private keys and plaintext request keys never leave trusted devices. Users may read only their own grants.

### Multi-Group Request Submission

The centered bottom `+` request action opens a request composer where the user selects one or more active groups with checkboxes and a `Select All` option.

Submitting to multiple groups must create one canonical `prayer_requests` document and one `request_shares` document per selected group. Each authorized recipient receives a `request_key_grants` document wrapping the same request content key to their public key. Do not create duplicate encrypted request documents for each group, and do not store plaintext request summaries.

If some group writes fail, successful group writes remain submitted. The client should show calm partial-success copy and allow retry for failed groups.

## `request_reports`

Stores metadata-only request reports for Leader review. Reports must not include plaintext request title, body, summaries, tags, notes, or free-text reasons.

Report IDs are scoped by request, group, and reporter: `{requestId}_{groupId}_{userId}`. This allows one canonical request to be reported through each group where it appears without cross-group collisions.

```json
{
  "groupId": "groupId",
  "requestId": "requestId",
  "reportedBy": "userId",
  "createdAt": "timestamp",
  "status": "open",
  "resolvedAt": null,
  "resolvedBy": null
}
```

Allowed statuses:

- `open`
- `dismissed`
- `removed`

Any active member may report a request in their group. Reports are visible only to Leaders in Group Settings. If a consolidated feed item is visible through multiple groups, reporting it creates one metadata-only report for each relevant group. Leaders may dismiss a report, archive the request, or remove the reported request from their group feed.

## `prayer_updates`

Stores encrypted updates, comments, answered-prayer notes, and pastoral follow-up notes.

```json
{
  "requestId": "requestId",
  "groupId": "groupId",
  "createdBy": "userId",
  "createdAt": "timestamp",
  "type": "follow_up",
  "visibility": "group",
  "keyVersion": 3,
  "payloadVersion": 1,
  "ciphertext": "base64",
  "nonce": "base64"
}
```

Allowed types:

- `update`
- `answered`
- `follow_up`
- `private_note`

## `prayer_actions`

Stores lightweight care actions that do not expose prayer content.

```json
{
  "requestId": "requestId",
  "userId": "userId",
  "type": "prayed",
  "createdAt": "timestamp"
}
```

Prayer participation counts are aggregated by canonical `requestId`, not by group. One request shared to two groups shows a total unique count across all groups, and a user who belongs to both groups counts once. Prayer participation may be shown quietly as care context, such as `3 joining in prayer`. Do not present these actions as likes, reactions, rankings, streaks, or engagement metrics.

## `prayer_sessions`

Stores encrypted user-specific scheduled prayer session configuration plus minimal reminder metadata.

```json
{
  "userId": "userId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "status": "active",
  "sortOrder": 1000,
  "reminder": {
    "enabled": true,
    "timeLocal": "07:30",
    "timezone": "America/New_York",
    "daysOfWeek": [1, 2, 3, 4, 5, 6, 7]
  },
  "payloadVersion": 1,
  "algorithm": "xchacha20-poly1305",
  "ciphertext": "base64",
  "nonce": "base64"
}
```

Encrypted payload contains session name, private labels, display preferences, and any custom data that could reveal spiritual habits. Reminder metadata is stored only to the extent required for scheduling generic reminders.

Allowed statuses:

- `active`
- `archived`
- `deleted`

## `routine_sections`

Stores ordered encrypted routine sections for a user's private prayer sessions.

```json
{
  "userId": "userId",
  "sessionId": "sessionId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "sortOrder": 2000,
  "type": "custom_text",
  "status": "active",
  "payloadVersion": 1,
  "algorithm": "xchacha20-poly1305",
  "ciphertext": "base64",
  "nonce": "base64"
}
```

Current section types:

- `custom_text`
- `request_feed`

Legacy stored values that clients should continue to parse as user sections:

- `heading`
- `silence`
- `reading_placeholder`

Encrypted payload contains section title, section type, labels, display options, request-feed slot configuration, and other user-authored routine content. Custom section body content uses Quill Delta JSON as the canonical rich text format:

```json
{
  "title": "Opening",
  "type": "custom_text",
  "contentFormat": "quill_delta_json",
  "contentDeltaJson": "[{\"insert\":\"Lord, open our lips.\\n\"}]"
}
```

`contentDeltaJson` is sensitive plaintext before encryption and must never be stored in Firestore outside the encrypted payload. A `request_feed` section stores placement and configuration only; it never stores request IDs or request content from a consolidated feed.

## `personal_prayers`

Stores user-supplied personal prayer book entries encrypted for the owning user.

```json
{
  "userId": "userId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "status": "active",
  "payloadVersion": 1,
  "algorithm": "xchacha20-poly1305",
  "ciphertext": "base64",
  "nonce": "base64"
}
```

Encrypted payload contains title, body, notes, tags, and user-authored prayer text. Personal prayers are encrypted only for the owning user unless intentionally included in a shared routine as custom text.

## `shared_routines`

Stores metadata for routines intentionally shared by a user.

```json
{
  "createdBy": "userId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "status": "active",
  "visibility": "direct",
  "recipientUserIds": ["userId"],
  "payloadVersion": 1,
  "algorithm": "xchacha20-poly1305",
  "ciphertext": "base64",
  "nonce": "base64"
}
```

Encrypted payload contains shared routine title, description, and any shared metadata. The routine's user-authored sections are intentionally shared with recipients, but still must not be readable by Firebase operators.

Allowed statuses:

- `active`
- `revoked`
- `deleted`

## `shared_routine_sections`

Stores ordered sections for a shared routine.

```json
{
  "sharedRoutineId": "sharedRoutineId",
  "createdBy": "userId",
  "createdAt": "timestamp",
  "sortOrder": 1000,
  "type": "request_feed",
  "payloadVersion": 1,
  "algorithm": "xchacha20-poly1305",
  "ciphertext": "base64",
  "nonce": "base64"
}
```

For user-authored sections, the encrypted payload contains the shared text and placement. For request-feed sections, the encrypted payload contains placement and display configuration only. It must not include the sharer's request IDs, request contents, group IDs as feed contents, or content-derived summaries.

## `devices`

Stores push notification tokens and device state.

```json
{
  "userId": "userId",
  "platform": "ios",
  "fcmToken": "token",
  "createdAt": "timestamp",
  "lastSeenAt": "timestamp",
  "appVersion": "1.0.0"
}
```

## `notifications`

Stores generic notification events.

```json
{
  "userId": "userId",
  "groupId": "groupId",
  "requestId": "requestId",
  "sessionId": "sessionId",
  "type": "new_request",
  "createdAt": "timestamp",
  "readAt": null
}
```

Notification documents and FCM payloads must not contain plaintext prayer request content, personal prayer content, routine custom text, or content-derived summaries.

Allowed generic notification types include:

- `new_request`
- `follow_up_reminder`
- `prayer_session_reminder`
- `join_request`
- `admin_change`

Prayer-session reminders should use generic copy such as `Time for prayer` or `Your prayer session is ready` unless the notification is generated locally on-device from decrypted data.

## `audit_events`

Stores security and administrative events without sensitive prayer text.

```json
{
  "groupId": "groupId",
  "actorUserId": "userId",
  "targetUserId": "userId",
  "type": "member_removed",
  "createdAt": "timestamp",
  "metadata": {
    "role": "member"
  }
}
```

Allowed group admin types include:

- `member_promoted`
- `leader_demoted`
- `member_removed`
- `invite_code_created`
- `invite_code_disabled`
- `join_request_approved`
- `join_request_rejected`
- `request_removed`
- `request_report_dismissed`

Audit metadata must not include prayer plaintext, routine content, personal prayer text, or content-derived summaries.

## Indexing Strategy

Recommended indexes:

- `group_members`: `userId`, `status`
- `group_members`: `groupId`, `status`, `role`
- `group_keys`: `groupId`, `userId`, `keyVersion`
- `invite_codes`: `codeHash`, `status`
- `invite_codes`: `groupId`, `status`, `createdAt`
- `join_requests`: `groupId`, `status`, `createdAt`
- `join_requests`: `requestedBy`, `status`, `createdAt`
- `prayer_requests`: `createdBy`, `status`, `createdAt` for personal feeds
- `request_shares`: `groupId`, `status`, `sharedAt` for group feeds
- `request_key_grants`: `userId`, `requestId`
- `request_reports`: `groupId`, `status`, `createdAt`
- `prayer_updates`: `requestId`, `createdAt`
- `prayer_actions`: `requestId`, `userId`, `type`
- `prayer_sessions`: `userId`, `status`, `sortOrder`
- `routine_sections`: `userId`, `sessionId`, `status`, `sortOrder`
- `personal_prayers`: `userId`, `status`, `updatedAt`
- `shared_routines`: `recipientUserIds`, `status`, `updatedAt` where supported by the chosen sharing model
- `shared_routine_sections`: `sharedRoutineId`, `sortOrder`
- `notifications`: `userId`, `readAt`, `createdAt`
- `audit_events`: `groupId`, `createdAt`

Avoid backend plaintext feed assembly. The consolidated request organizer should be assembled client-side from active memberships, request shares, canonical encrypted requests, and local decryption through request key grants.

## Security Rules Requirements

- Users may only read groups where they have an active membership.
- Users may only read their own encrypted group keys.
- Users may create private canonical prayer requests for themselves.
- Users may share requests only to groups where they are active members.
- Multi-group request submission must create one canonical encrypted request, one share per group, and encrypted request key grants for authorized recipients.
- Group members may read request statuses such as `active`, `answered`, `resolved`, and `archived` according to membership access.
- Request reports may be created by active members and read or resolved only by Leaders.
- Any active member may create invite codes when group settings allow member invites.
- Join requests may be read by the requester and group Leaders, but only Leaders may approve or reject them.
- Only Leaders may promote, demote, or remove members, and rules or backend validation must prevent removal or demotion of the last active Leader.
- Users may only read and write their own private `prayer_sessions`, `routine_sections`, and `personal_prayers` unless an explicit encrypted sharing flow applies.
- Shared routines may be read only by intended recipients or according to the chosen sharing visibility, and shared content must remain encrypted.
- Anonymous Firebase users are prohibited.
- Removed or blocked members cannot read future group content.
- Clients cannot write server-owned fields such as aggregate counts without validation.
- Cloud Functions must validate membership before fanout, invite, join request, admin, or notification operations.

Security rules protect access boundaries, not plaintext confidentiality. Encryption remains mandatory.
