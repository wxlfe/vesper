# Accessibility

Vesper should be usable by people in emotionally sensitive moments, on small mobile screens, with assistive technologies, and under varied visual or motor conditions.

## Requirements

- WCAG AA contrast minimum
- Dynamic Type or platform text scaling support
- Screen reader support
- Reduced motion support
- High touch target sizes
- Keyboard and switch-access compatibility where platform-relevant

Minimum tap target:

```text
44x44
```

## Text Scaling

Layouts must tolerate larger text sizes without clipping critical actions. Prayer request detail screens should prioritize readable body text and should not force dense metadata into the main reading flow.

## Color Contrast

All text and meaningful UI controls must meet WCAG AA contrast. Do not communicate status through color alone. Pair semantic color with labels, icons, or shape changes.

## Screen Readers

Screen reader labels should be clear and calm.

Examples:

```text
Prayer request from Sarah, shared yesterday
End-to-end encrypted
Mark as prayed
Follow up reminder, tomorrow at 9 AM
```

Avoid exposing implementation details such as ciphertext, key versions, or sync IDs unless the user is in a support/debug flow.

## Motion Sensitivity

Respect platform reduced motion settings. Disable non-essential animation and replace spatial transitions with opacity changes.

## Touch And Motor Accessibility

- Use at least `44x44` touch targets.
- Keep destructive actions separated from primary actions.
- Avoid swipe-only interactions for critical workflows.
- Provide confirmation for destructive or irreversible actions.
- Keep care actions reachable without requiring precise gestures.

## Cognitive Accessibility

Prayer requests may be written or read during stressful moments. UI copy should be direct, reassuring, and low-pressure.

Prefer:

```text
This request is private to your group.
You can save this and finish later.
This action could not sync. Try again when you are online.
```

Avoid:

```text
Fatal sync error
Invalid cryptographic payload
Engagement opportunity missed
```

## Privacy Accessibility

Privacy indicators should be understandable without technical knowledge. Pair concise labels with optional deeper explanations.

Recommended short labels:

- End-to-end encrypted
- Private to this group
- Vesper cannot read this request
