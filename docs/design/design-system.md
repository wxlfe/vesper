# Design System

The Vesper design system should make private prayer collaboration feel peaceful, trustworthy, and modern. The interface should be spacious and emotionally lightweight rather than dense, gamified, or institutional.

## Brand

The product name should be presented to users as `Vesper` with a capital `V`. Internal package names, IDs, and code symbols may remain lowercase where platform conventions require it.

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

The core palette should feel like twilight: quiet, reflective, and softly luminous. Use violet-gray surfaces and restrained periwinkle accents to suggest evening prayer without becoming decorative, mystical, or neon.

### Light Mode

```text
Background:     #f5f2f8
Surface:        #ffffff
Primary text:   #211f2d
Secondary text: #6f697d
Accent:         #6d5f99
Divider:        #e5dfec
```

### Dark Mode

```text
Background:     #11101a
Surface:        #1c1a28
Primary text:   #f3f0f8
Secondary text: #aaa3ba
Accent:         #a99ad6
Divider:        #343043
```

Dark mode should feel like twilight: quiet, low-glare, and softly luminous. Avoid neon purple, saturated blue, high-contrast cyber aesthetics, and high-saturation accent colors unless used for critical semantic states.

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

When a requester profile is available, show the person's display name in quiet metadata such as `Sarah · active · May 18`. Fall back to calm generic language when a profile is unavailable. Do not expose raw user IDs in normal UI.

Requests awaiting approval should use quiet status language such as `waiting for approval` or `needs review`. Do not make pending requests feel rejected, urgent, or publicly exposed. In approval-required groups, pending request cards should only appear for the author and Leaders with approval permission.

Request authors may see owner-only actions to `Update`, `Remove`, or mark the request `Answered` inside a three-dot overflow menu. Keep these actions secondary and calm; removal should not use alarming language. Do not show the `Prayed` action on a user's own requests. For other people's requests, double-tap may mark the request as prayed for without adding public reaction mechanics.

### Row Action Menus

Long-press action menus may reveal secondary options on group and member rows, but they must not be the only way to perform critical workflows. Keep menu actions labeled, calm, and separated from the row's primary tap target.

For group rows, long-pressing may reveal `Pin` or `Unpin`, `Share`, and `Leave`. Pinned groups should appear in a `Pinned Groups` section above the full group list. For Member rows in Leader-only Group Settings, long-pressing may reveal `Promote` and `Remove`. Promotion and removal actions should create pending consensus changes rather than immediately changing access.

### Profile Screen

The Profile screen should keep account management quiet and practical: editable display name first, the user's own prayer requests across groups next, and a low-emphasis `Log out` action at the bottom. Avoid making logout the primary home-screen action.

### Prayed Action

The interaction should feel personal, gentle, and affirming. It should not appear on a user's own requests.

Use:

- Soft fade animation
- Light haptic
- Subtle confirmation text

Avoid counters, streaks, or public reaction mechanics.

### Privacy Messaging

Privacy messaging should be subtle and trustworthy. Encryption can be explained on the initial landing/onboarding screen for new users, but it should not be repeatedly advertised throughout normal app flows because it adds visual weight and displaces prayer and group context.

Examples:

```text
end-to-end encrypted
only your group can read this
Vesper cannot access prayer contents
```

Avoid cybersecurity-style fear messaging.

Do not show persistent encryption cards, badges, or banners on ordinary group, request, or settings screens unless the user is in an onboarding, help, or recovery context.

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
