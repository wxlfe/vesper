# Design System

The Vesper design system should make private prayer collaboration feel peaceful, trustworthy, and modern. The interface should be spacious and emotionally lightweight rather than dense, gamified, or institutional.

## Brand

The product name is `vesper` in brand contexts. Use lowercase when presenting the wordmark or brand label.

Design attributes:

- Quiet
- Pastoral
- Trustworthy
- Softly structured
- Privacy-respecting
- Modern without feeling trendy

Avoid attributes:

- Corporate
- Social-media-like
- Flashy
- Overly decorative
- Urgent
- Surveillance-oriented

## Typography

Primary font: Inter.

Fallback stack:

- `system-ui`
- SF Pro
- Roboto

### Type Scale

Display:

```css
font-size: 40-48px;
font-weight: 600;
line-height: 1.1;
letter-spacing: -0.02em;
```

Heading:

```css
font-size: 28-34px;
font-weight: 600;
line-height: 1.2;
```

Body:

```css
font-size: 16-18px;
font-weight: 400-500;
line-height: 1.6;
```

Metadata:

```css
font-size: 12-13px;
font-weight: 500;
letter-spacing: 0.04em;
```

## Color

### Light Mode

```text
Background:     #f6f5f2
Surface:        #ffffff
Primary text:   #1f1f1d
Secondary text: #6b6b67
Accent:         #6f7c6b
Divider:        #e5e2dc
```

### Dark Mode

```text
Background:     #121311
Surface:        #1b1d1a
Primary text:   #f2f1ed
Secondary text: #a4a39d
Accent:         #8c9a87
Divider:        #30322e
```

Dark mode should feel candlelit rather than neon. Avoid high-saturation accent colors unless used for critical semantic states.

## Semantic Color

Use semantic color sparingly.

Recommended meanings:

- Success: answered prayer, completed follow-up, saved state
- Warning: expiring invitation, sync issue, pending approval
- Error: failed sync, lost access, destructive action
- Info: encryption explanation, offline state, neutral guidance

Semantic colors must meet WCAG AA contrast requirements.

## Spacing

Use generous spacing and reduce visual density.

Preferred spacing scale:

```text
4
8
12
16
24
32
48
64
```

Primary screen padding should usually be `24` on mobile, with tighter values allowed for dense lists and smaller devices.

## Shape

Primary radius:

```text
20-28
```

Use rounded containers to create a gentle, tactile feel. Avoid excessive pill shapes where they reduce clarity.

## Elevation

Prefer subtle layering over strong shadows.

Use:

- Layered surfaces
- Soft borders
- Low-opacity shadows
- Translucency where platform-appropriate
- Soft blur sparingly

Avoid strong material shadows and floating-card clutter.

## Iconography

Preferred icon library: Lucide.

Rules:

- Thin strokes
- Rounded geometry
- Restrained usage
- Icons support labels rather than replacing them in critical actions

Avoid excessive icons, filled icon sets, novelty religious symbols, and icons that imply public engagement metrics.

## Components

### Prayer Request Card

Should show only the minimum needed context: group, author display state, age, status, and a short decrypted preview if appropriate. Avoid public counts and social ranking.

### Prayed Button

The interaction should feel personal, gentle, and affirming.

Use:

- Soft fade animation
- Light haptic
- Subtle confirmation text

Avoid counters, streaks, or public reaction mechanics.

### Privacy Badge

Privacy messaging should be subtle and trustworthy.

Examples:

```text
end-to-end encrypted
only your group can read this
vesper cannot access prayer contents
```

Avoid cybersecurity-style fear messaging.

### Empty States

Empty states should be calm and useful. They should invite prayer, care, or setup without sounding like growth software.

## Content Tone

Use short, gentle language. Prefer plain speech over theological jargon.

Good examples:

```text
Share a prayer request
This request is private to your group
You can come back to this later
```

Avoid:

```text
Boost engagement
Your group is inactive
Don't miss out
```
