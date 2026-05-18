# Firestore Schema

Firestore stores encrypted prayer data, membership metadata, notification routing data, and operational state. Sensitive prayer content must be encrypted before it is written.

## Collection Overview

```text
users/{userId}
groups/{groupId}
group_members/{membershipId}
group_keys/{groupKeyId}
prayer_requests/{requestId}
prayer_updates/{updateId}
prayer_actions/{actionId}
notifications/{notificationId}
invitations/{invitationId}
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
    "allowAnonymous": true,
    "requireApproval": true,
    "allowMemberInvites": false
  }
}
```

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

- `owner`
- `admin`
- `pastor`
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
  "algorithm": "x25519-xchacha20-poly1305",
  "createdAt": "timestamp",
  "createdBy": "userId",
  "status": "active"
}
```

A user may only read their own `group_keys` documents.

## `prayer_requests`

Stores encrypted request payloads plus non-sensitive routing metadata.

```json
{
  "groupId": "groupId",
  "createdBy": "userId",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "status": "active",
  "anonymous": false,
  "keyVersion": 3,
  "payloadVersion": 1,
  "ciphertext": "base64",
  "nonce": "base64",
  "metadata": {
    "hasFollowup": true,
    "hasReminder": false,
    "updateCount": 2
  }
}
```

Encrypted payload contains title, body, private notes, sensitive tags, care details, and any content-derived summary.

Allowed statuses:

- `active`
- `answered`
- `resolved`
- `archived`
- `deleted`

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

## `invitations`

Stores invite lifecycle metadata.

```json
{
  "groupId": "groupId",
  "emailHash": "sha256-base64",
  "invitedBy": "userId",
  "role": "member",
  "status": "pending",
  "createdAt": "timestamp",
  "expiresAt": "timestamp",
  "acceptedBy": null
}
```

Prefer hashed email routing where possible. Do not store invite messages containing sensitive prayer content.

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
- `prayer_requests`: `groupId`, `status`, `updatedAt`
- `prayer_updates`: `requestId`, `createdAt`
- `prayer_actions`: `requestId`, `userId`, `type`
- `notifications`: `userId`, `readAt`, `createdAt`

Avoid global feeds and cross-group queries.

## Security Rules Requirements

- Users may only read groups where they have an active membership.
- Users may only read their own encrypted group keys.
- Users may only create prayer requests for groups where they are active members.
- Anonymous Firebase users are prohibited.
- Removed or blocked members cannot read future group content.
- Clients cannot write server-owned fields such as aggregate counts without validation.
- Cloud Functions must validate membership before fanout or invite operations.

Security rules protect access boundaries, not plaintext confidentiality. Encryption remains mandatory.
