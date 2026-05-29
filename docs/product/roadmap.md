# Product Roadmap

Vesper's roadmap prioritizes private prayer routines and secure group prayer collaboration first, then routine sharing and pastoral workflow depth, then broader church organization support.

## Product Goals

- Help users build a private prayer rhythm from user-supplied prayer text and group requests.
- Help churches and small groups manage prayer requests securely.
- Make end-to-end encryption understandable without making the product feel technical.
- Encourage prayer, care, and follow-up without gamification.
- Keep group administration simple for Leaders.
- Use a restrained illuminated manuscript visual language that supports prayer and reading.

## Phase 1: MVP

Core features:

- Authentication with email/password
- User public key registration
- Global illuminated manuscript design language
- Primary Prayer home screen
- Home FAB for creating a prayer request
- Group checkbox selector in the request composer
- `Select All` option for multi-group request submission
- Group creation
- Copyable group invite codes and Leader-approved join requests
- Simplified Leader and Member roles
- Immediate request publishing with member reports and Leader removal/archive tools
- Leader promotion, demotion, and member removal with confirmation
- Last-Leader protection
- Metadata-only admin history
- Encrypted group keys
- Encrypted prayer requests
- One encrypted prayer request document per selected group on multi-group submission
- Author-managed request updates, removal, and answered status
- Prayer acknowledgements
- Request status changes
- Follow-up reminders
- User-defined scheduled prayer sessions
- User-private prayer book
- Routine builder with custom text sections, headings, silence, and request-feed sections
- Cross-device sync for encrypted routine structure and personal prayers
- Generic prayer-session reminders
- Dark mode
- Basic offline viewing and queued writes

Success criteria:

- Users can create and join groups.
- Prayer request content is unreadable from Firebase Console.
- Group members can read decrypted requests on trusted devices.
- Request authors can update, remove, and mark their own requests as answered without exposing plaintext to Firestore.
- Users can create a scheduled prayer session from user-supplied content.
- Users can place their request feed inside a prayer routine.
- User-supplied prayer text and routine custom text are unreadable from Firebase Console.
- Users can submit one request to one, many, or all of their groups from the home FAB.
- Invite-code join requests show Leaders who requested access and who invited them.
- Group administration feels simple, safe, and accountable without committee-style workflows.
- The product feels like a calm, private, illuminated prayer book rather than a social feed or admin console.

Deferred from MVP:

- Leader consensus governance
- 24-hour dispute windows
- Group request approval policy
- Pending settings changes
- Custom roles and permission matrices
- Organization-level administration
- Built-in prayer-book, lectionary, or denominational office text

## Phase 2: Routine Sharing And Pastoral Depth

Candidate features:

- Apple and Google authentication
- Generic push notifications beyond MVP reminders
- Routine sharing
- Shared routine adoption and copying
- More advanced recurrence rules for scheduled prayers
- Template import/export for user-authored structures
- Richer routine section types
- Deep-link invitations once Vesper has an app link domain
- Anonymous requests
- Attachment support with encrypted files and metadata
- Recovery passphrases
- Advanced pastoral workflows
- Care assignments
- Answered prayer history
- Group moderation controls
- Improved offline conflict handling
- Limited web support with documented trust tradeoffs

Routine sharing must follow these rules:

- Shared routines include all sections and ordering.
- Shared custom text sections include the user's shared content.
- Shared request-feed sections include only placement and configuration.
- The recipient's request-feed section is populated from the recipient's own groups.
- The sharer's group requests and request feed contents are never copied into the shared routine.

## Phase 3: Church Operations

Candidate features:

- Church organization hierarchy
- Ministry-level administration
- Role templates, only if simple Leader/Member groups prove insufficient
- Audit exports without prayer plaintext
- Invitation policy controls
- Retention policy controls
- More granular approval roles and review queues, only if justified by larger church needs
- Integration exploration for church management systems
- Optional SSO or magic links

## Long-Term Considerations

- Encrypted search strategy
- Multi-device key synchronization
- Hardware-backed key attestation where practical
- Account recovery workflows that preserve user trust
- Enterprise controls for larger churches
- Prayer routine portability without bundling third-party prayer-book text

## Implementation Notes

Initial implementation targets the Firebase project `vesper-47594`, app name `Vesper`, bundle/package name `dev.wxlfe.vesper`, and version `0.1.0`. iOS is the first validation target, with Android kept close behind through Flutter. MVP validation should use local/debug builds before TestFlight, Play internal testing, or production release workflows.

## Non-Goals

- Public social networking
- Public prayer feeds
- Viral sharing
- Ad-driven engagement
- Content recommendation algorithms
- Behavioral profiling
- Prayer content analytics
- Bundled copyrighted prayer-book content
- Backend-readable personal prayer or routine content

## Feature Specs

Detailed feature specs should live in `docs/product/feature-specs/` as features become ready for design and implementation.

Current specs:

- [Group Governance](./feature-specs/group-governance.md)
- [Personal Prayer Routines](./feature-specs/personal-prayer-routines.md)
- [Simplified Groups And Request Composer](./feature-specs/simplified-groups-and-request-composer.md)

Recommended spec template:

```text
# Feature Name

## Problem
## Goals
## Non-Goals
## User Stories
## UX Notes
## Data Model
## Security And Privacy
## Offline Behavior
## Acceptance Criteria
## Open Questions
```
