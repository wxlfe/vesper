---
name: vesper-flutter-architecture
description: Use when implementing Vesper Flutter application code, Riverpod state, feature folders, Firebase services, repositories, secure storage, local cache, or shared widgets.
---

# Vesper Flutter Architecture

Use this skill when adding or restructuring Vesper Flutter application code.

## Preferred Stack

- Flutter for iOS and Android in Phase 1.
- Riverpod for state management unless a later documented decision changes this.
- Firebase Authentication, Firestore, Cloud Functions, Cloud Messaging, and App Check for backend services.
- Platform secure storage through iOS Keychain and Android Keystore-backed storage.
- Local encrypted cache for offline viewing and queued writes.

## Project Structure

Prefer this structure when application code is introduced:

```text
lib/
  core/
    crypto/
    models/
    services/
    theme/
    widgets/
  features/
    auth/
    groups/
    notifications/
    profile/
    requests/
  shared/
  main.dart
```

Crypto responsibilities belong under `lib/core/crypto`:

```text
lib/core/crypto/
  key_manager.dart
  encryption_service.dart
  secure_storage_service.dart
  group_key_service.dart
```

## Boundaries

- Keep encryption and key lifecycle logic out of UI widgets.
- Keep Firebase SDK calls in services or repositories, not directly in screens.
- Keep feature-specific state near the feature unless it is truly cross-cutting.
- Keep shared widgets visual and reusable; avoid embedding product workflows in shared components.
- Keep Cloud Functions free of plaintext prayer content and plaintext key material.

## Riverpod Guidance

- Model asynchronous Firebase and local cache reads explicitly.
- Keep providers small and feature-scoped where possible.
- Avoid global mutable state for decrypted prayer content.
- Dispose listeners and subscriptions according to provider lifecycle.
- Prefer clear domain names over generic provider names.

## Offline And Sync

- Preserve offline viewing through encrypted local cache only.
- Queue writes without storing sensitive plaintext unencrypted.
- Make sync errors calm, retryable, and understandable.
- Avoid conflict handling that silently drops user-entered care notes or request updates.

## Before Completing Work

- Run relevant Flutter analysis and tests when available.
- Verify encrypted data boundaries with focused unit tests for crypto and mapping logic.
- Update docs when architecture, schema, or product behavior changes.
