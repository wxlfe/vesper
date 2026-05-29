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
- Gentle manuscript-style section reveals
- Soft transitions into prayer sessions and routine sections
- A clear but quiet center request action-to-composer transition

Avoid:

- Springy reward motion
- Confetti
- Streak effects
- Bouncy tab transitions
- Flashy notification animations
- Motion that imitates social media engagement loops
- Page-flip gimmicks
- Glittering gold or shimmering ornament effects
- Decorative animation that competes with prayer text
- Autoplay-like movement through routine steps
- High-velocity feed snapping that feels addictive

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
- Fade or gentle reveal for illuminated dividers and section headers

Prayer routine transitions should feel like moving through a quiet reading order. They should not imply a score, streak, or completion game.

Full-screen routine steps may use vertical paging. This is a spatial reading pattern, not an entertainment feed pattern. Keep paging calm, predictable, and user-controlled. Avoid bounce, acceleration, autoplay, infinite continuation, and attention-seeking snap effects.

## Request Composer

Opening the prayer request composer from the centered bottom `+` action should preserve orientation and make the audience-selection step clear. Use a bottom sheet or full-screen composer depending on available space. The group checkbox list should appear without dramatic motion, and `Select All` state changes should be immediate and understandable.

## Routine Row

The `Pray` tab routine row may scroll horizontally, but it should feel like choosing a section of a prayer book rather than browsing social content. Avoid animated rings, auto-advancing previews, unseen-count motion, or other story-feed mechanics.

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
- Disable ornamental section reveals and any page-like movement.
- Replace full-screen routine step paging with simple fades or non-animated position changes where practical.
