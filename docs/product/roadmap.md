# Product Roadmap

Vesper's roadmap prioritizes secure prayer collaboration first, then pastoral workflow depth, then broader church organization support.

## Product Goals

- Help churches and small groups manage prayer requests securely.
- Make end-to-end encryption understandable without making the product feel technical.
- Encourage prayer, care, and follow-up without gamification.
- Keep operational overhead low for Leaders.

## Phase 1: MVP

Core features:

- Authentication with email/password
- User public key registration
- Group creation
- Copyable group invite codes and Leader-approved join requests
- Group request publishing setting: approve before publishing or publish immediately
- Encrypted group keys
- Encrypted prayer requests
- Author-managed request updates, removal, and answered status
- Leader and Member roles
- Group settings changes with Leader-visible approvals, disputes, promotion, removal, and delayed activation
- Prayer acknowledgements
- Request status changes
- Follow-up reminders
- Dark mode
- Basic offline viewing and queued writes

Success criteria:

- Users can create and join groups.
- Prayer request content is unreadable from Firebase Console.
- Group members can read decrypted requests on trusted devices.
- Request authors can update, remove, and mark their own requests as answered without exposing plaintext to Firestore.
- Groups can choose whether member-created requests require Leader approval before publication.
- Invite-code join requests show Leaders who requested access and who invited them.
- Group settings changes remain private to Leaders until they take effect.
- The product feels safe, peaceful, trustworthy, simple, and thoughtful.

## Phase 2: Pastoral Depth

Candidate features:

- Apple and Google authentication
- Generic push notifications
- Deep-link invitations once Vesper has an app link domain
- Anonymous requests
- Attachment support with encrypted files and metadata
- Recovery passphrases
- Advanced pastoral workflows
- Care assignments
- Answered prayer history
- Group moderation controls
- More granular approval roles and review queues
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
- Account recovery workflows that preserve user trust
- Enterprise controls for larger churches

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

## Feature Specs

Detailed feature specs should live in `docs/product/feature-specs/` as features become ready for design and implementation.

Current specs:

- [Group Governance](./feature-specs/group-governance.md)

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
