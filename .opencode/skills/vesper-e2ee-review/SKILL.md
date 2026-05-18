---
name: vesper-e2ee-review
description: Use when designing, implementing, testing, or reviewing Vesper end-to-end encryption, key management, encrypted payloads, group keys, invitations, member removal, attachments, or recovery flows.
---

# Vesper E2EE Review

Use this skill for all Vesper cryptography and key-management work.

## Core Model

- Sensitive prayer content exists in plaintext only on trusted user devices.
- The backend stores encrypted payloads, encrypted key material, and non-sensitive routing metadata only.
- User public keys may be stored in Firestore.
- User private keys remain local in secure storage.
- Group keys are symmetric keys generated on trusted devices and encrypted separately for each member.

## Preferred Primitives

- XChaCha20-Poly1305 for authenticated symmetric encryption.
- X25519 for public-key key agreement or sealed-box style key wrapping.
- Ed25519 only if message authenticity beyond AEAD is needed.
- Secure random generation from platform cryptographic APIs.

Avoid custom cryptography, custom key derivation, unauthenticated encryption, reused nonces, and hand-rolled signed/encrypted serialization formats.

## Encrypted Payload Shape

Encrypted documents should include enough metadata for decryption and migration:

```json
{
  "ciphertext": "base64",
  "nonce": "base64",
  "keyVersion": 3,
  "payloadVersion": 1,
  "algorithm": "xchacha20-poly1305"
}
```

Use authenticated additional data to bind ciphertext to stable context:

- Document ID
- Group ID
- Collection name
- Key version
- Payload version

## Request Encryption Workflow

- Load active membership for the group.
- Fetch the encrypted group key assigned to the current user.
- Decrypt the group key locally with the user's private key.
- Serialize the sensitive request payload.
- Encrypt with the group key and a fresh nonce.
- Upload ciphertext, nonce, key version, payload version, algorithm, and non-sensitive metadata.

## Request Decryption Workflow

- Download encrypted request metadata and ciphertext.
- Resolve the matching encrypted group key by `groupId`, `userId`, and `keyVersion`.
- Decrypt the group key locally.
- Decrypt the request payload locally.
- Render plaintext without logging it or writing it to unencrypted storage.

## Membership Review

- Group creation must generate the group key on the creator device.
- Invitations require the admin device to encrypt the active group key to the invitee public key.
- The server must never receive the plaintext group key.
- Member removal should rotate the group key for future content.
- Historical revocation requires re-encryption and should not be implied unless implemented.

## Test Expectations

- Round-trip encryption and decryption succeeds for valid payloads.
- Decryption fails when AAD context changes.
- Decryption fails with wrong key version or member key.
- Nonces are unique for repeated encryptions.
- Firestore DTOs never expose sensitive plaintext fields.
- Logs and thrown errors do not include decrypted payloads or key material.
