---
name: vesper-calm-ux
description: Use when designing or implementing Vesper screens, motion, copy, notifications, accessibility behavior, prayer request interactions, care workflows, or visual polish.
---

# Vesper Calm UX

Use this skill for Vesper product, UI, interaction, copy, notification, and accessibility work.

## Product Feel

Vesper should feel:

- Trustworthy
- Quiet
- Pastoral
- Modern
- Privacy-respecting
- Emotionally lightweight

Vesper should not feel:

- Corporate
- Gamified
- Social-media-like
- Surveillance-oriented
- Overly decorative
- Aggressively religious

## Interaction Rules

- Avoid public reactions, likes, streaks, viral feeds, public counters, and engagement loops.
- Keep care actions simple: prayed, follow up, resolve, archive.
- Avoid urgency unless there is a real pastoral workflow need.
- Keep destructive actions separated from primary actions.
- Avoid swipe-only interactions for critical workflows.
- Provide confirmation for destructive or irreversible actions.

## Accessibility Requirements

- Meet WCAG AA contrast for text and meaningful controls.
- Support platform text scaling without clipping critical actions.
- Use at least `44x44` touch targets.
- Respect reduced motion settings.
- Support screen readers with calm, clear labels.
- Do not communicate status through color alone.

## Motion

- Motion should clarify state changes and hierarchy.
- Avoid flashy, celebratory, gamified, or attention-seeking animation.
- Replace non-essential spatial transitions with opacity changes when reduced motion is enabled.

## Copy

Prefer direct, reassuring, low-pressure copy:

```text
This request is private to your group.
You can save this and finish later.
This action could not sync. Try again when you are online.
```

Avoid technical or alarming copy in normal user flows:

```text
Fatal sync error
Invalid cryptographic payload
Engagement opportunity missed
```

## Privacy Language

Use privacy labels people can understand without cybersecurity knowledge:

- End-to-end encrypted
- Private to this group
- Vesper cannot read this request

## Notifications

Notifications must be generic and must not include prayer request plaintext or content-derived summaries.

Allowed examples:

```text
New request in your group
Check in with someone today
Three requests awaiting follow-up
```
