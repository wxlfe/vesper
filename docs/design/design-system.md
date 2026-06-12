# Design System

The Vesper design system should make private prayer collaboration feel quiet, readable, trustworthy, and emotionally lightweight. Vesper supports two app themes: `Traditional`, the default manuscript-inspired style, and `Contemporary`, a modern Material style. Both themes must preserve the same privacy-first workflows and can use the same Theme Color choices.

## Brand

The product name should be presented to users as `Vesper` with a capital `V`. Internal package names, IDs, and code symbols may remain lowercase where platform conventions require it.

Design attributes:

- Quiet
- Pastoral
- Prayerful
- Trustworthy
- Manuscript-inspired by default
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

The Traditional theme uses an illuminated manuscript style consistently throughout the app. This means cream surfaces, traditional serif typography, restrained ornament, rubric-like section labels, and colors drawn from parchment, ink, muted gold, oxblood, lapis, malachite, and warm umber. The app should not feel like a novelty medieval interface; manuscript references should support prayer, structure, and reading.

The Contemporary theme uses modern Material styling with platform sans-serif typography, simpler surfaces, less ornament, and system light/dark mode behavior. It must keep the same navigation, privacy behavior, request workflows, and available Theme Color choices as Traditional.

## Theme Settings

`Theme` controls the visual style:

- `Traditional`: default manuscript-inspired style.
- `Contemporary`: modern Material style that follows the device light/dark mode.

`Theme Color` controls the primary accent independently of theme style. Liturgical, fixed, and custom colors must be available in both Traditional and Contemporary themes.

## Typography

Traditional primary reading and heading font: a traditional, highly readable serif.

Recommended candidates:

- `Libre Baskerville`
- `Cormorant Garamond`
- `Source Serif 4`
- `Georgia`

Contemporary typography should use platform sans-serif fonts similar to Helvetica, such as San Francisco on iOS and Roboto on Android. Utility font for dense metadata and controls, when needed: a quiet humanist sans or platform system font.

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

The core palette should feel like parchment, ink, and restrained illumination. Cream backgrounds should be warm without becoming yellowed or low contrast. Accent colors should be rich but muted. The primary UI accent follows the Western Gregorian liturgical calendar so the app quietly reflects the current season without changing layout or meaning.

### Light Mode

```text
Background:     #fbf3df
Surface:        #fffaf0
Raised surface: #f6ead1
Primary text:   #241c14
Secondary text: #6f5f4a
Muted text:     #8c7a61
Divider:          #dfcfab
Gold accent:      #b58a32
Ordinary green:   #208070
Advent/Lent:      #583070
Epiphany lapis:   #294f7a
Pentecost red:    #8f2f2f
Good Friday ink:  #151515
Malachite:        #4f6f53
Umber:            #7a5635
```

### Dark Mode

```text
Background:     #19130d
Surface:        #241b12
Raised surface: #302418
Primary text:   #f6ead1
Secondary text: #c9b894
Muted text:     #a8926c
Divider:             #4a3826
Gold accent:         #d1aa55
Ordinary green:      #8eb28b
Advent/Lent:         #a78bd0
Epiphany lapis:      #8fb4d8
Pentecost red:       #c46a60
Good Friday ash:     #9a9a9a
Malachite:           #8eb28b
Umber:               #c2925f
```

Dark mode should feel like warm ink and candlelit parchment, not cyber, neon, or high-glare. Avoid saturated blue, bright green, and high-contrast gold-on-black ornament unless contrast and visual calm are preserved.

### Seasonal Primary Accent

The primary UI color is seasonal, based on the Western Gregorian church calendar:

- Ordinary Time: green
- Advent, Lent, and Holy Week outside Good Friday: purple
- Christmas and Easter: muted gold
- Epiphany: lapis
- Pentecost: oxblood red
- Good Friday: ink black in light mode and ash gray in dark mode

Seasonal color affects atmosphere only. It must never be the only indication of status, selection, privacy, errors, completion, or current routine position. Foreground colors must be chosen for contrast against each seasonal primary.

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

### Pray Tab

The `Pray` tab is the signed-in landing screen. It should feel like opening a personal prayer book, not checking a dashboard.

Use:

- A horizontal routine row at the top
- An always-visible `Create Routine` action
- A consolidated request feed below routines
- Quiet access to routine and prayer book editing inside the `Pray` tab

Avoid dashboard clutter, rankings, public counts, streaks, or urgency-driven modules.

### Bottom App Bar

The signed-in app should use a bottom app bar with two tabs and a centered primary request action:

```text
Pray        +        Groups
```

Rules:

- `Pray` is the left tab and the default landing tab after login.
- `Groups` is the right tab.
- The centered `+` opens the request composer.
- The centered `+` is not a tab and should not have a selected state.
- Profile and account actions should live in secondary header or menu actions.

The center action should be visually clear, reachable, and labeled for assistive technologies as `Submit prayer request` or `Create prayer request`. It may use a manuscript accent color such as oxblood, lapis, or malachite, but it must meet contrast requirements and should not dominate the reading experience.

### Routine Row

Routines on the `Pray` tab should appear in a horizontally scrollable row of circular icons with short labels, visually similar to the layout pattern of Instagram Stories but without social-story behavior.

Use:

- Circular routine icons with manuscript-inspired initials or quiet ornament
- Short routine names below or near each icon
- A clearly visible `Create Routine` control whether routines exist or not
- Calm selected/pressed states that do not imply public activity

Avoid:

- Viewer indicators
- Expiration rings
- Public activity rings
- Streaks
- Reactions
- Auto-advancing content
- Algorithmic promotion of routines

The routine row should sit vertically above the consolidated request feed.

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

Prayer routines are ordered collections of user-arranged sections. They may include user-authored sections and a request-feed section. The request-feed section is included by default and dynamically populated with requests available to the viewing user.

Selecting a routine opens a routine screen that guides the user step-by-step through the routine. The routine screen may use a TikTok-like full-screen vertical paging layout as a spatial pattern only: each step takes up the full screen and the user scrolls vertically through the routine order. It must not borrow TikTok's engagement mechanics.

Routine screens should emphasize reading flow:

- Large readable serif text
- Clear section breaks
- Restrained illuminated dividers
- Low-pressure progress through the routine
- Easy exit and resume behavior
- Accessible next and previous movement in addition to scrolling

Avoid completion streaks, progress pressure, gamified rewards, public completion indicators, autoplay, infinite feeds, algorithmic recommendations, and attention-seeking snap effects.

Request steps inside a routine should preserve the existing `Join in prayer` action. Joining in prayer should remain personal and quiet, with no public reaction mechanics.

### Prayer Book Entry

Personal prayer entries should feel private and book-like. Custom text is user-supplied and encrypted on-device. Vesper should not ship prayer-book text.

### Prayer Request Card

Should show only the minimum needed context: group, author display state, age, status, and a short decrypted preview if appropriate. Avoid public counts and social ranking.

When a requester profile is available, show the person's display name in quiet metadata such as `Sarah · active · May 18`. Fall back to calm generic language when a profile is unavailable. Do not expose raw user IDs in normal UI.

Request authors may see owner-only actions to `Update`, `Remove`, or mark the request `Answered` inside a three-dot overflow menu. Keep these actions secondary and calm; removal should not use alarming language. Do not show the `Prayed` action on a user's own requests. For other people's requests, double-tap may mark the request as prayed for without adding public reaction mechanics.

### Group Administration

Group administration should be lightweight and focused on membership and trust. All group creation, joining, administration, and group-specific request feeds belong in the `Groups` tab.

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
