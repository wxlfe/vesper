# Firestore Schema

Firestore stores encrypted prayer data, membership metadata, notification routing data, and operational state. Sensitive prayer content must be encrypted before it is written.

## Collection Overview

```text
users/{userId}
groups/{groupId}
group_members/{membershipId}
group_keys/{groupKeyId}
invite_codes/{inviteCodeId}
join_requests/{joinRequestId}
group_settings_changes/{changeId}
prayer_requests/{requestId}
prayer_updates/{updateId}
prayer_actions/{actionId}
notifications/{notificationId}
devices/{deviceId}
audit_events/{eventId}
```

Use deterministic composite IDs where they reduce duplication and simplify rules. For example, `group_members/{groupId_userId}` and `group_keys/{groupId_userId_keyVersion}`.

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

`displayName` is non-sensitive profile metadata used for member lists, Leader-facing join request review, settings change descriptions, and prayer request attribution inside groups. Do not copy display names into encrypted prayer payloads or use them in notification copy that could reveal request context.

Do not store private keys, recovery phrases, or plaintext pastoral notes.

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
    "allowAnonymous": false,
    "requireApproval": true,
    "allowMemberInvites": true
  }
}
```

`settings.requireApproval` controls request publishing for the group. When `true`, new member-created requests start as `pending_approval` and must be approved by a Leader before they appear in the normal group feed. When `false`, new requests are published immediately as `active` after upload.

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

A user may only read their own `group_keys` documents.

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

Leaders may read pending join requests for their groups. The request should show Leaders who requested access and, when known, who invited them. Approving a join request creates or activates the membership and requires a Leader device to encrypt the active group key for the requester.

## `group_settings_changes`

Stores Leader-only proposed group settings changes. This includes request publishing policy changes, Leader additions, and Member removals.

```json
{
  "groupId": "groupId",
  "type": "add_leader",
  "proposedBy": "userId",
  "targetUserId": "userId",
  "proposedSettings": {
    "requireApproval": false
  },
  "status": "pending",
  "createdAt": "timestamp",
  "expiresAt": "timestamp",
  "resolvedAt": null,
  "approvals": {
    "leaderUserId": "timestamp"
  },
  "disputes": {
    "leaderUserId": {
      "createdAt": "timestamp"
    }
  }
}
```

Allowed types:

- `add_leader`
- `remove_member`
- `publishing_policy`

Allowed statuses:

- `pending`
- `approved`
- `disputed`
- `expired_approved`
- `cancelled`

Group settings change records are visible only to current Leaders. Members, including a Member targeted for Leader access or removal, must not be able to read pending, disputed, cancelled, or expired settings change records. Proposed changes take effect only when all Leaders approve early or the 24-hour dispute window closes with no disputes. Any dispute cancels the change and remains visible to Leaders. A `remove_member` change marks the target membership as `removed` only after consensus completes.

## `prayer_requests`

Stores encrypted request payloads plus non-sensitive routing metadata.

```json
{
  "groupId": "groupId",
  "createdBy": "userId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "status": "pending_approval",
  "anonymous": false,
  "keyVersion": 3,
  "payloadVersion": 1,
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

Encrypted payload contains title, body, private notes, sensitive tags, care details, and any content-derived summary.

Allowed statuses:

- `pending_approval`
- `active`
- `answered`
- `resolved`
- `archived`
- `deleted`

`pending_approval` requests are not published to the whole group feed. The author and Leaders with approval permission may read the encrypted request, review it on-device after decryption, and transition it to `active` or another terminal status. Groups with `settings.requireApproval: false` should create requests directly as `active`.

Request authors may manage their own requests after creation. Updating a request must re-encrypt the title and body on-device before writing replacement ciphertext. Removing a request should transition it to `deleted` rather than deleting the document directly. Authors may also mark their own requests as `answered`.

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
  "groupId": "groupId",
  "userId": "userId",
  "type": "prayed",
  "createdAt": "timestamp"
}
```

Avoid public counters and engagement metrics in the UI even if aggregate counts are stored for product behavior.

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
  "type": "new_request",
  "createdAt": "timestamp",
  "readAt": null
}
```

Notification documents and FCM payloads must not contain plaintext prayer request content.

For groups that require approval, notification events for the full group should be created only after a request transitions to a published status. Approval queue notifications may route to approving Leaders, but must use generic event types and copy such as `pending_request_review`.

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

## Indexing Strategy

Recommended indexes:

- `group_members`: `userId`, `status`
- `group_members`: `groupId`, `status`, `role`
- `group_keys`: `groupId`, `userId`, `keyVersion`
- `invite_codes`: `codeHash`, `status`
- `invite_codes`: `groupId`, `status`, `createdAt`
- `join_requests`: `groupId`, `status`, `createdAt`
- `join_requests`: `requestedBy`, `status`, `createdAt`
- `group_settings_changes`: `groupId`, `status`, `expiresAt`
- `prayer_requests`: `groupId`, `status`, `updatedAt`
- `prayer_requests`: `groupId`, `status`, `createdAt` for approval queues
- `prayer_updates`: `requestId`, `createdAt`
- `prayer_actions`: `requestId`, `userId`, `type`
- `notifications`: `userId`, `readAt`, `createdAt`

Avoid global feeds and cross-group queries.

## Security Rules Requirements

- Users may only read groups where they have an active membership.
- Users may only read their own encrypted group keys.
- Users may only create prayer requests for groups where they are active members.
- Groups with approval enabled must restrict `pending_approval` request reads to the author and Leaders who can approve requests.
- Group members may read published request statuses such as `active`, `answered`, `resolved`, and `archived` according to membership access.
- Any active member may create invite codes when group settings allow member invites.
- Join requests may be read by the requester and group Leaders, but only Leaders may approve or reject them.
- Group settings change records may be read only by current Leaders and must never be readable by Members, including a targeted Member.
- A Member's role may change to `leader`, and publishing policy may change, only after the group settings change workflow approves early or reaches the end of its dispute window without disputes.
- Anonymous Firebase users are prohibited.
- Removed or blocked members cannot read future group content.
- Clients cannot write server-owned fields such as aggregate counts without validation.
- Cloud Functions must validate membership before fanout, invite, join request, or settings change operations.

Security rules protect access boundaries, not plaintext confidentiality. Encryption remains mandatory.
