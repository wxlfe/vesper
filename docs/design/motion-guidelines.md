# Motion Guidelines

Motion in Vesper should feel calm, intentional, and reverent. Animation should help users understand state changes without creating urgency or reward loops.

## Principles

- Motion should clarify, not entertain.
- Transitions should feel soft and grounded.
- Feedback should be noticeable but never flashy.
- Haptics should be light and used sparingly.
- Reduced motion preferences must be respected.

## Recommended Motion

Use:

- Fades
- Subtle slide transitions
- Gentle scale changes
- Slow easing
- Soft haptics
- Skeleton or shimmer alternatives that do not feel frantic

Avoid:

- Springy reward motion
- Confetti
- Streak effects
- Bouncy tab transitions
- Flashy notification animations
- Motion that imitates social media engagement loops

## Timing

Recommended ranges:

```text
Micro feedback:     100-180ms
Screen transitions: 220-320ms
Modal transitions:  180-260ms
Content fades:      160-240ms
```

Use slower timing for reflective state changes and faster timing for direct manipulation feedback.

## Easing

Prefer ease-out for entering elements and ease-in-out for state transitions. Avoid highly elastic curves.

Recommended feel:

```text
enter: soft ease-out
exit: short ease-in
state: gentle ease-in-out
```

## Screen Transitions

Screen transitions should preserve orientation and reduce cognitive load.

Recommended patterns:

- Fade through for top-level navigation
- Subtle horizontal slide for drill-in navigation
- Bottom sheet rise for contextual actions
- Crossfade for decrypted content becoming available

## Prayer Interaction

The `prayed` action should feel like a quiet acknowledgement.

Recommended sequence:

1. Button softens or fills subtly.
2. Optional light haptic fires.
3. Confirmation text appears briefly.
4. UI settles without displaying a public counter.

## Loading States

Loading states should avoid anxiety.

Use calm labels:

```text
opening request
syncing quietly
preparing your group
```

Avoid dramatic or technical labels unless needed for support.

## Reduced Motion

When reduced motion is enabled:

- Replace slides and scales with fades.
- Disable non-essential decorative movement.
- Keep haptics optional.
- Avoid parallax.
- Keep progress indicators simple.
