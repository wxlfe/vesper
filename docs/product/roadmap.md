# Product Roadmap

Vesper's roadmap prioritizes secure prayer collaboration first, then pastoral workflow depth, then broader church organization support.

## Product Goals

- Help churches and small groups manage prayer requests securely.
- Make end-to-end encryption understandable without making the product feel technical.
- Encourage prayer, care, and follow-up without gamification.
- Keep operational overhead low for group leaders.

## Phase 1: MVP

Core features:

- Authentication with email/password, Apple, and Google
- User public key registration
- Group creation
- Group invitations and approvals
- Encrypted group keys
- Encrypted prayer requests
- Prayer acknowledgements
- Request status changes
- Follow-up reminders
- Generic push notifications
- Dark mode
- Basic offline viewing and queued writes

Success criteria:

- Users can create and join groups.
- Prayer request content is unreadable from Firebase Console.
- Group members can read decrypted requests on trusted devices.
- Notifications never include prayer request plaintext.
- The product feels safe, peaceful, trustworthy, simple, and thoughtful.

## Phase 2: Pastoral Depth

Candidate features:

- Anonymous requests
- Attachment support with encrypted files and metadata
- Recovery passphrases
- Advanced pastoral workflows
- Care assignments
- Answered prayer history
- Group moderation controls
- Organization-level church support
- Improved offline conflict handling
- Limited web support with documented trust tradeoffs

## Phase 3: Church Operations

Candidate features:

- Church organization hierarchy
- Ministry-level administration
- Role templates
- Audit exports without prayer plaintext
- Invitation policy controls
- Retention policy controls
- Integration exploration for church management systems
- Optional SSO or magic links

## Long-Term Considerations

- Encrypted search strategy
- Multi-device key synchronization
- Hardware-backed key attestation where practical
- Admin recovery workflows that preserve user trust
- Enterprise controls for larger churches

## Non-Goals

- Public social networking
- Public prayer feeds
- Viral sharing
- Ad-driven engagement
- Content recommendation algorithms
- Behavioral profiling
- Prayer content analytics

## Feature Specs

Detailed feature specs should live in `docs/product/feature-specs/` as features become ready for design and implementation.

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
