# Design System

The Vesper design system should make private prayer collaboration feel like a quiet, personal prayer book: reverent, readable, trustworthy, and gently illuminated. The visual language is globally inspired by illuminated manuscripts, but it must remain calm and useful rather than decorative for its own sake.

## Brand

The product name should be presented to users as `Vesper` with a capital `V`. Internal package names, IDs, and code symbols may remain lowercase where platform conventions require it.

Design attributes:

- Quiet
- Pastoral
- Prayerful
- Trustworthy
- Manuscript-inspired
- Privacy-respecting
- Warm and readable

Avoid attributes:

- Corporate
- Social-media-like
- Flashy
- Theme-park medieval
- Visually cluttered
- Surveillance-oriented
- Aggressively religious

Vesper should use an illuminated manuscript style consistently throughout the app. This means cream surfaces, traditional serif typography, restrained ornament, rubric-like section labels, and colors drawn from parchment, ink, muted gold, oxblood, lapis, malachite, and warm umber. The app should not feel like a novelty medieval interface; manuscript references should support prayer, structure, and reading.

## Typography

Primary reading and heading font: a traditional, highly readable serif.

Recommended candidates:

- `Libre Baskerville`
- `Cormorant Garamond`
- `Source Serif 4`
- `Georgia`

Utility font for dense metadata and controls, when needed: a quiet humanist sans or platform system font.

Fallback stack:

- Georgia
- `Times New Roman`
- serif

Rules:

- Use serif type for prayer text, routine sections, headings, request detail, and primary reading surfaces.
- Use small caps or letter-spaced metadata sparingly for rubrics, group labels, and routine section markers.
- Avoid fragile display faces for body text.
- Avoid overly calligraphic fonts for interactive controls.
- Preserve legibility at large text sizes.

### Type Scale

Display:

```css
font-size: 40-48px;
font-weight: 600;
line-height: 1.12;
letter-spacing: -0.01em;
```

Heading:

```css
font-size: 28-34px;
font-weight: 600;
line-height: 1.22;
```

Body:

```css
font-size: 17-19px;
font-weight: 400;
line-height: 1.65;
```

Metadata and rubrics:

```css
font-size: 12-13px;
font-weight: 600;
letter-spacing: 0.06em;
text-transform: uppercase;
```

## Color

The core palette should feel like parchment, ink, and restrained illumination. Cream backgrounds should be warm without becoming yellowed or low contrast. Accent colors should be rich but muted.

### Light Mode

```text
Background:     #fbf3df
Surface:        #fffaf0
Raised surface: #f6ead1
Primary text:   #241c14
Secondary text: #6f5f4a
Muted text:     #8c7a61
Divider:        #dfcfab
Gold accent:    #b58a32
Oxblood:        #8f2f2f
Lapis:          #294f7a
Malachite:      #4f6f53
Umber:          #7a5635
```

### Dark Mode

```text
Background:     #19130d
Surface:        #241b12
Raised surface: #302418
Primary text:   #f6ead1
Secondary text: #c9b894
Muted text:     #a8926c
Divider:        #4a3826
Gold accent:    #d1aa55
Oxblood:        #c46a60
Lapis:          #8fb4d8
Malachite:      #8eb28b
Umber:          #c2925f
```

Dark mode should feel like warm ink and candlelit parchment, not cyber, neon, or high-glare. Avoid saturated blue, bright green, and high-contrast gold-on-black ornament unless contrast and visual calm are preserved.

## Illumination And Ornament

Use illuminated graphics as quiet structural accents:

- Initial capitals for major reading sections
- Thin borders around important reading cards
- Small vine, leaf, star, or geometric marks as dividers
- Rubric-style labels for routine instructions
- Muted gold linework for section transitions
- Simple manuscript-inspired empty-state illustrations

Avoid:

- Dense frames around long-form reading
- Animated glitter or shimmering gold
- Novelty religious clip art
- Ornament that competes with prayer text
- Decoration that reduces touch target clarity
- Any state communicated only through ornament or color

## Semantic Color

Use semantic color sparingly.

Recommended meanings:

- Success: answered prayer, completed follow-up, saved state
- Warning: expiring invitation, sync issue, pending retry
- Error: failed sync, lost access, destructive action
- Info: encryption explanation, offline state, neutral guidance

Semantic colors must meet WCAG AA contrast requirements and must be paired with labels, icons, or shape changes.

## Spacing

Use generous spacing and reduce visual density. Prayer routines should feel like reading a page, not managing a task list.

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

Primary screen padding should usually be `24` on mobile, with tighter values allowed for dense lists and smaller devices. Reading surfaces may use slightly wider vertical spacing for calm pacing.

## Shape

Primary radius:

```text
16-24
```

Use softened rectangles, parchment panels, and framed reading surfaces. Avoid excessive pill shapes where they reduce clarity or feel visually unrelated to the manuscript language.

## Elevation

Prefer layering, borders, and paper-like tonal shifts over strong shadows.

Use:

- Layered parchment surfaces
- Thin ink or gold borders
- Low-opacity shadows
- Subtle inset panels
- Soft dividers

Avoid strong material shadows, floating-card clutter, and glassmorphism that conflicts with the prayer-book feel.

## Iconography

Preferred icon style: thin, restrained line icons with rounded geometry.

Rules:

- Icons support labels rather than replacing them in critical actions.
- Use icons sparingly and keep them secondary to text.
- Manuscript-inspired marks may be used as decoration, not as unlabeled controls.

Avoid excessive icons, filled icon sets, novelty religious symbols, and icons that imply public engagement metrics.

## Components

### Prayer Home

The primary home screen should center the user's next prayer session or daily prayer routine. It should feel like opening a personal prayer book, not checking a dashboard.

Use:

- A clear next scheduled prayer session
- Quiet access to the user's prayer book
- A request-feed preview only when it helps the routine
- A floating action button for creating a prayer request

Avoid dashboard clutter, rankings, public counts, streaks, or urgency-driven modules.

### Floating Action Button

The home screen should include a FAB for creating a prayer request. It should be visually clear, reachable, and labeled for assistive technologies as `Create prayer request`.

The FAB may use a manuscript accent color such as oxblood, lapis, or malachite, but it must meet contrast requirements and should not dominate the reading experience.

### Prayer Request Composer

When authoring a prayer request, the user should choose which groups receive it.

The group selector should show:

- The groups where the user is an active member
- A checkbox for each eligible group
- A `Select All` option
- A selected-count summary
- Calm validation when no group is selected

Submitting to multiple groups creates separate encrypted requests, one per selected group. The UI should make the audience clear before submission.

### Prayer Routine

Prayer routines are ordered collections of user-arranged sections. They may include custom text, headings, silence, and a request-feed section. The request-feed section is dynamically populated with requests available to the viewing user.

Routine screens should emphasize reading flow:

- Large readable serif text
- Clear section breaks
- Restrained illuminated dividers
- Low-pressure progress through the routine
- Easy exit and resume behavior

Avoid completion streaks, progress pressure, gamified rewards, or public completion indicators.

### Prayer Book Entry

Personal prayer entries should feel private and book-like. Custom text is user-supplied and encrypted on-device. Vesper should not ship prayer-book text.

### Prayer Request Card

Should show only the minimum needed context: group, author display state, age, status, and a short decrypted preview if appropriate. Avoid public counts and social ranking.

When a requester profile is available, show the person's display name in quiet metadata such as `Sarah · active · May 18`. Fall back to calm generic language when a profile is unavailable. Do not expose raw user IDs in normal UI.

Request authors may see owner-only actions to `Update`, `Remove`, or mark the request `Answered` inside a three-dot overflow menu. Keep these actions secondary and calm; removal should not use alarming language. Do not show the `Prayed` action on a user's own requests. For other people's requests, double-tap may mark the request as prayed for without adding public reaction mechanics.

### Group Administration

Group administration should be lightweight and focused on membership and trust.

Use:

- Member list
- Invite code or share action
- Join request review
- Promote, demote, and remove member actions for Leaders
- Confirmation before destructive or access-changing actions
- Metadata-only admin history

Avoid custom role matrices, approval bureaucracy, public moderation theater, and enterprise-style settings unless a future roadmap phase requires them.

### Row Action Menus

Long-press action menus may reveal secondary options on group and member rows, but they must not be the only way to perform critical workflows. Keep menu actions labeled, calm, and separated from the row's primary tap target.

For group rows, long-pressing may reveal `Pin` or `Unpin`, `Share`, and `Leave`. Pinned groups should appear in a `Pinned Groups` section above the full group list. For Member rows in Leader-only Group Settings, long-pressing may reveal `Promote`, `Demote`, and `Remove`, with confirmation for access-changing actions.

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

Examples:

```text
No requests are ready here yet.
Add a prayer to this session.
Choose a group before sharing this request.
```

## Content Tone

Use short, gentle language. Prefer plain speech over unnecessary theological jargon. The app may use terms like prayer, session, routine, and prayer book, but should not assume a specific prayer-book tradition in product copy.

Good examples:

```text
Share a prayer request
This request is private to your group
You can come back to this later
Time for prayer
```

Avoid:

```text
Boost engagement
Your group is inactive
Don't miss out
Complete your streak
```
