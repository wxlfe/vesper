---
name: vesper-privacy-guard
description: Use when implementing or reviewing Vesper features that touch prayer content, Firestore writes, Cloud Functions, notifications, logs, analytics, crash reporting, or telemetry; enforces privacy and plaintext-handling rules.
---

# Vesper Privacy Guard

Use this skill before implementing or reviewing any Vesper feature that handles sensitive content, persistence, backend orchestration, notifications, logging, analytics, crash reporting, or telemetry.

## Sensitive Content

Treat all of the following as sensitive plaintext:

- Prayer request title
- Prayer request body
- Private notes
- Pastoral care notes
- Sensitive tags
- Private comments
- Attachment metadata
- Content-derived summaries
- Plaintext group keys
- User private keys

## Hard Rules

- Never store sensitive plaintext in Firestore.
- Never send sensitive plaintext through Cloud Functions.
- Never include sensitive plaintext in push notifications.
- Never write sensitive plaintext to logs, analytics, performance traces, crash reports, telemetry, or support dumps.
- Never store user private keys or plaintext group keys on the backend.
- Encrypt sensitive content on-device before persistence or upload.
- Treat Firebase Security Rules as access control only, not as the confidentiality boundary.
- Use generic notification copy only.

## Implementation Checklist

- Confirm sensitive fields are encrypted before any repository, service, or SDK write.
- Confirm DTOs sent to Firestore contain encrypted payloads and non-sensitive routing metadata only.
- Confirm Cloud Functions operate only on metadata, membership state, notification routing, and encrypted blobs.
- Confirm logs redact encrypted payload fields where practical and never interpolate decrypted content.
- Confirm analytics events avoid prayer content, derived sentiment, topics, tags, keywords, and body length heuristics.
- Confirm errors shown to users are calm and non-technical unless in a support/debug flow.

## Allowed Non-Sensitive Metadata

Non-sensitive metadata may include:

- Group IDs
- Document IDs
- Timestamps
- Coarse status
- Membership role
- Notification preference
- Encrypted payload version
- Key version
- Algorithm identifier

## Review Questions

- Could Firebase Console, logs, Cloud Functions, notifications, analytics, or crash reporting reveal prayer content?
- Does any helper, mapper, or debug statement accidentally expose decrypted data?
- Does any notification contain a title, body, name, tag, or summary derived from prayer content?
- Would a database export reveal only ciphertext and non-sensitive metadata?
