# Group Governance

## Problem

Prayer groups need a simple way to invite people, approve membership, and entrust additional Leaders without turning group administration into an enterprise workflow or committee process.

## Goals

- Keep group roles simple with `leader` and `member`.
- Allow any active member to invite people to a group through copyable invite codes when enabled.
- Require Leader approval before an invited person becomes a member.
- Show Leaders who requested to join and, when known, who invited them.
- Allow any Leader to promote, demote, or remove members with confirmation.
- Prevent demoting or removing the last active Leader.
- Publish member-created requests immediately and allow any member to report a request.
- Show request reports to Leaders in Group Settings.
- Allow Leaders to archive or remove another member's request, whether reported or not.
- Record access-changing administrative actions as metadata-only audit events.

## Non-Goals

- Public group discovery.
- Immediate invite-code membership without review.
- Leader consensus governance in the MVP.
- 24-hour dispute windows.
- Group-level request approval policies.
- Complex role templates or organization-wide permission systems.
- Deep-link invitation infrastructure before Vesper has an app link domain.

## User Stories

- As a Member, I can copy an invite code for my group so someone can request to join.
- As an invited person, I can enter an invite code and request access to the group.
- As a Leader, I can see pending join requests in Group Settings with requester and inviter display names when available.
- As a Leader, I can approve a join request and grant the new member access to the encrypted group key.
- As a Leader, I can reject a join request without exposing prayer content.
- As a Leader, I can promote a Member to Leader with confirmation.
- As a Leader, I can demote another Leader as long as another active Leader remains.
- As a Leader, I can remove a member with confirmation and clear access-loss copy.
- As a Leader, I cannot remove or demote the last active Leader.
- As a Member, I can report another request to Leaders without creating public engagement signals.
- As a Leader, I can dismiss a report, archive a request, or remove the reported request.
- As a Leader, I can review metadata-only admin history for my group.

## UX Notes

Use the term `Leader` in product copy and `leader` in stored role values. Avoid `admin`, `owner`, and `pastor` as product roles unless a future organization model introduces more granular role templates.

Invite codes should feel calm and practical. The current implementation generates copyable `VESPER-` codes with a seven-day default expiration and stores only a normalized code hash for lookup. The invite flow should explain that entering a code requests access and that a Leader will review the request. Avoid language that implies rejection is public or urgent.

Group Settings should be available inside a group only to Leaders. Settings should be lightweight: invite codes, join requests, member list, reports, and admin history. Avoid approval bureaucracy and enterprise-style configuration.

Promotion, demotion, and removal actions should require confirmation. Removal copy should be plain and calm, such as `They will lose access to future requests.` Key rotation should happen quietly in the background.

Long-press menus may reveal secondary options without being the only way to perform access-control changes. On the home group list, long-pressing a group row may open a menu with `Pin`, `Share`, and `Leave`. In Group Settings, long-pressing an active Member row may open a menu with `Promote`, `Demote`, and `Remove` where applicable.

## Data Model

Use the canonical collections in [Firestore Schema](../../architecture/firestore-schema.md):

- `group_members` with roles `leader` and `member`.
- `invite_codes` for hashed copyable invite-code metadata.
- `join_requests` for invite-code membership requests.
- `group_keys` for encrypted group key delivery after membership approval.
- `request_reports` for metadata-only request reports.
- `audit_events` for metadata-only admin history.

The group creator is automatically created as an active `leader`. Approved invite-code join requests create or activate a `member` membership.

Request reports include only group ID, request ID, reporter ID, status, and timestamps. Reports must not include plaintext request content, content summaries, sensitive tags, private notes, or free-text reasons.

Administrative audit events include group ID, actor ID, target ID where relevant, type, timestamp, and non-sensitive metadata. Audit events must not include prayer plaintext, request summaries, personal prayer text, or routine content.

## Security And Privacy

Invite codes and join requests must not contain prayer content. The backend may store membership metadata, invite routing metadata, timestamps, and role state, but it must never receive plaintext group keys or prayer content.

Approving a join request requires a Leader device or trusted client flow to encrypt the active group key for the requester. Cloud Functions may validate workflow state, but they must not handle plaintext group keys.

Request reports must be readable only by current Leaders. Report metadata must not reveal prayer content beyond the fact that a request was reported.

Promotion, demotion, and removal require current Leader authorization. Rules or backend validation must prevent removal or demotion of the last active Leader.

## Offline Behavior

Users may view previously synced group membership state offline. Invite-code creation, join request approval, promotion, demotion, removal, and key rotation should require current server state before taking effect because they change access control.

Queued governance writes should be treated carefully. If a user's role, membership status, or group key version changes before replay, the client should revalidate permissions before submitting.

## Acceptance Criteria

- A group creator becomes an active Leader automatically.
- Active Members can create copyable invite codes when the group allows member invites.
- Entering an invite code creates a join request, not membership.
- Leaders can see requester and inviter display names on join requests when both profiles are available.
- Approving a join request creates or activates Member access and encrypts the group key for that user.
- Rejecting a join request does not expose prayer content.
- A Leader can access Group Settings from inside a group.
- A Leader can promote an active Member to Leader with confirmation.
- A Leader can demote another Leader when at least one other Leader remains.
- A Leader can remove a member with confirmation.
- Last-Leader demotion and removal are blocked.
- Access-changing admin actions create metadata-only audit events.
- Member-created requests publish immediately as active requests.
- Any active member can report a request.
- Reports are visible only to Leaders in Group Settings.
- Leaders can dismiss reports, archive requests, or remove reported requests.
- Leaders can remove another member's request even when it has not been reported.

## Open Questions

- Should invite codes support explicit usage limits beyond the current default expiration?
- Should demotion of a Leader rotate group keys immediately, or only if the Leader is also removed?
