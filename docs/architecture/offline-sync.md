# Offline Sync

Offline support is important because prayer and pastoral care often happen in low-connectivity settings. Vesper should support reading previously synced requests, drafting new requests, and queueing care actions while offline.

## Goals

- Allow users to view previously synced prayer requests offline.
- Allow users to draft and submit requests while offline.
- Queue low-risk actions such as `prayed`, archive, or follow-up reminders.
- Keep cached content encrypted at rest.
- Resolve conflicts without exposing plaintext to backend services.

## Non-Goals

- Full collaborative editing
- Global offline search over decrypted content
- Server-side conflict resolution using plaintext
- Offline access for groups whose keys are not already available locally

## Local Storage

Preferred approach: encrypted local database plus platform secure storage.

Candidate databases:

- Drift
- Hive
- Isar

Sensitive content should be encrypted before local persistence. The local database may store encrypted payloads exactly as received from Firestore, plus local sync state.

## Local Key Material

User private keys live in iOS Keychain or Android Keystore-backed secure storage. Group keys may be cached locally only if protected by platform secure storage or an app-level encrypted key store.

Local key cache should support:

- Fast offline decryption for active groups
- Key version lookup
- Removal when membership is removed
- App lock or biometric gates if added later

## Cache Model

Recommended local tables or boxes:

```text
cached_groups
cached_memberships
cached_group_keys
cached_prayer_requests
cached_prayer_updates
pending_writes
sync_cursors
```

Cached request records should preserve remote IDs, group IDs, key versions, ciphertext, nonce, timestamps, and local sync state.

## Pending Writes

Pending writes should be stored locally as encrypted operations.

```json
{
  "operationId": "uuid",
  "type": "create_prayer_request",
  "groupId": "groupId",
  "createdAt": "timestamp",
  "attemptCount": 0,
  "state": "pending",
  "encryptedPayload": {
    "ciphertext": "base64",
    "nonce": "base64",
    "keyVersion": 3
  }
}
```

Do not store plaintext drafts in local storage unless the storage layer is encrypted and the product explicitly accepts the risk. Prefer encrypting drafts with the active group key before persistence.

## Sync Strategy

### Initial Sync

1. Fetch active memberships.
2. Fetch assigned encrypted group keys.
3. Decrypt and cache usable group keys locally.
4. Fetch recent request metadata and ciphertext by group.
5. Store encrypted records locally.
6. Decrypt only when rendering UI.

### Incremental Sync

Use group-scoped cursors based on `updatedAt` or snapshot listeners. Keep sync windows narrow and paginate historical data.

### Write Replay

1. Check current membership and active key version.
2. Re-encrypt queued drafts if the active key changed before upload.
3. Apply the group's current publishing policy: submit as `pending_approval` when approval is required, otherwise submit as `active`.
4. Mark successful operations as synced.
5. Keep failed operations with a clear retryable or blocked state.

## Conflict Handling

Prayer requests are mostly append-oriented, which should minimize conflicts. Prefer explicit state transitions over in-place text editing.

Common conflicts:

- Request archived remotely while user adds an update offline
- Group key rotates while user has queued content
- User removed from group before pending write replay
- Same request updated from multiple devices
- Group request approval setting changes while a request is queued offline

Recommended behavior:

- Use last-write-wins only for non-sensitive metadata where acceptable.
- Preserve encrypted updates as append-only records.
- Block replay if membership is no longer active.
- Re-encrypt pending writes with the current key version when the user still has access.
- Use the server-side group approval setting at replay time rather than the setting captured when the draft was created.
- Show a calm resolution message when an action cannot be completed.

## Firestore Offline Persistence

Firestore's built-in offline persistence may be useful for metadata and encrypted payloads, but it does not replace the need for a deliberate encrypted local cache. Treat Firestore persistence as an optimization, not the primary security boundary.

## Cache Retention

Recommended defaults:

- Keep active group requests cached for recent history.
- Allow users to clear local cache.
- Remove cached group keys and request payloads when a user leaves or is removed from a group.
- Respect organization retention settings when introduced.

## UX Requirements

- Clearly indicate offline state without alarming users.
- Allow drafting while offline when the group key is available.
- Explain blocked actions in plain language.
- Avoid showing technical encryption errors unless needed for support.
