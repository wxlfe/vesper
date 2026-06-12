# Offline Sync

Offline support is important because prayer and pastoral care often happen in low-connectivity settings. Vesper should support reading previously synced requests, praying through saved routines, drafting new requests, editing personal prayer content, and queueing care actions while offline.

## Goals

- Allow users to view previously synced prayer requests offline.
- Allow users to view previously synced prayer sessions, routine sections, and personal prayers offline.
- Allow users to draft and submit requests while offline.
- Allow users to queue edits to encrypted prayer routines and personal prayer book entries.
- Queue low-risk actions such as `prayed`, archive, or follow-up reminders.
- Keep cached content encrypted at rest.
- Resolve conflicts without exposing plaintext to backend services.

## Non-Goals

- Full collaborative editing
- Global offline search over decrypted content
- Server-side conflict resolution using plaintext
- Offline access for groups whose keys are not already available locally
- Backend assembly of a global consolidated request feed

## Local Storage

Preferred approach: encrypted local database plus platform secure storage.

Candidate databases:

- Drift
- Hive
- Isar

Sensitive content should be encrypted before local persistence. The local database may store encrypted payloads exactly as received from Firestore, plus local sync state.

The current Phase 1 scaffold uses `EncryptedCacheService` as a lightweight bridge for offline viewing. It stores the encrypted Firestore request records for a group and decrypts only when rendering. This is acceptable for early validation, but it should be replaced by the deliberate encrypted local database described above before broader release.

## Local Key Material

User private keys live in iOS Keychain or Android Keystore-backed secure storage. Group keys may be cached locally only if protected by platform secure storage or an app-level encrypted key store.

Local key cache should support:

- Fast offline decryption for active groups
- Key version lookup
- Removal when membership is removed
- App lock or biometric gates if added later
- User-private content keys for prayer sessions, routine sections, and personal prayers

## Cache Model

Recommended local tables or boxes:

```text
cached_groups
cached_memberships
cached_group_keys
cached_prayer_requests
cached_prayer_updates
cached_prayer_sessions
cached_routine_sections
cached_personal_prayers
cached_shared_routines
pending_writes
sync_cursors
```

Cached request records should preserve canonical request IDs, share group IDs where applicable, key versions, ciphertext, nonce, timestamps, request key grant metadata, and local sync state.

Cached routine and personal prayer records should preserve remote IDs, owner user ID, payload version, ciphertext, nonce, timestamps, ordering metadata, and local sync state. Decrypt only when rendering the prayer routine or editing a prayer book entry.

## Pending Writes

Pending writes should be stored locally as encrypted operations.

```json
{
  "operationId": "uuid",
  "type": "create_prayer_request",
  "groupIds": ["groupId"],
  "createdAt": "timestamp",
  "attemptCount": 0,
  "state": "pending",
  "encryptedPayload": {
    "ciphertext": "base64",
    "nonce": "base64",
    "keyVersion": 1
  }
}
```

Do not store plaintext drafts in local storage unless the storage layer is encrypted and the product explicitly accepts the risk. Prefer encrypting drafts with a generated request content key before persistence.

Multi-group request submission should be represented as one pending canonical encrypted request write plus one pending share/key-grant operation per selected group. If some share or grant writes fail, keep failed group-share work retryable without duplicating the canonical request.

Routine edits and personal prayer edits should also be queued as encrypted operations. Private custom text, routine names, and prayer book content must not be written to a plaintext local queue.

## Sync Strategy

### Initial Sync

1. Fetch active memberships.
2. Fetch assigned encrypted group keys.
3. Decrypt and cache usable group keys locally.
4. Fetch recent request share metadata by group.
5. Fetch canonical request metadata, ciphertext, and the current user's request key grants.
6. Fetch user prayer sessions, routine sections, personal prayers, and shared routines assigned to the user.
7. Store encrypted records locally.
8. Decrypt only when rendering UI.

### Incremental Sync

Use group-scoped cursors based on `updatedAt` or snapshot listeners. Keep sync windows narrow and paginate historical data.

The consolidated request organizer should be assembled locally from active memberships, cached request shares, canonical request records, request key grants, and on-device decryption. Do not introduce backend plaintext feed assembly.

### Write Replay

1. Check current membership and active key version.
2. Re-encrypt queued drafts if the active key changed before upload.
3. Submit the request as `active`; groups do not require Leader approval before publication.
4. Mark successful operations as synced.
5. Keep failed operations with a clear retryable or blocked state.

For routine and prayer book writes:

1. Confirm the user is still authenticated and has local user-private content key material.
2. Re-encrypt queued routine or personal prayer changes if the local content key changed.
3. Submit encrypted records and minimal metadata.
4. Mark successful operations as synced.
5. Keep failed operations retryable without exposing plaintext in logs or diagnostics.

## Conflict Handling

Prayer requests are mostly append-oriented, which should minimize conflicts. Prefer explicit state transitions over in-place text editing.

Common conflicts:

- Request archived remotely while user adds an update offline
- Group key rotates while user has queued content
- User removed from group before pending write replay
- Same request updated from multiple devices
- Prayer session edited on another device while offline
- Routine section order changed on multiple devices
- Personal prayer edited on multiple devices

Recommended behavior:

- Use last-write-wins only for non-sensitive metadata where acceptable.
- Preserve encrypted updates as append-only records.
- Block replay if membership is no longer active.
- Re-encrypt pending writes with the current key version when the user still has access.
- Show a calm resolution message when an action cannot be completed.
- For private routine conflicts, preserve the latest encrypted version and prefer explicit duplicate/copy recovery over silent plaintext merging.
- For section ordering conflicts, use stable sort keys and preserve all sections where possible.

Group approval settings are not part of the MVP. If a future phase reintroduces approval policies, offline replay must use the current server-side policy at replay time.

## Prayer Routines Offline

Previously synced prayer sessions should be available offline, including user-authored sections, personal prayers, and request-feed slots. Request-feed slots should use cached group requests that the user can decrypt locally.

If the user has no cached requests for a request-feed slot, show calm empty copy. If a user loses access to a group, remove cached group keys and hide or remove future inaccessible requests from the routine feed.

Scheduled reminder preferences should sync across devices where practical. Backend-triggered reminders may use minimal plaintext scheduling metadata, but notification copy must remain generic. Local notifications may use decrypted session names only when generated on-device and allowed by platform behavior.

## Shared Routines Offline

Shared routine templates should be cached encrypted for recipients. Custom text sections in a shared routine are intentionally shared with recipients, but must remain encrypted at rest locally and in Firestore.

Request-feed sections in shared routines are dynamic. Offline rendering should populate them from the recipient's cached request feed, never from the sharer's request feed.

## Firestore Offline Persistence

Firestore's built-in offline persistence may be useful for metadata and encrypted payloads, but it does not replace the need for a deliberate encrypted local cache. Treat Firestore persistence as an optimization, not the primary security boundary.

## Cache Retention

Recommended defaults:

- Keep active group requests cached for recent history.
- Keep active prayer sessions, routine sections, and personal prayers cached for offline prayer.
- Allow users to clear local cache.
- Remove cached group keys and request payloads when a user leaves or is removed from a group.
- Respect organization retention settings when introduced.

## UX Requirements

- Clearly indicate offline state without alarming users.
- Allow drafting while offline when the group key is available.
- Allow praying through previously synced routines offline.
- Allow routine and prayer book editing offline when user-private key material is available.
- Explain blocked actions in plain language.
- Avoid showing technical encryption errors unless needed for support.
