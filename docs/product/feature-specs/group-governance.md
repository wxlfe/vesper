# Group Governance

## Problem

Prayer groups need a simple way to invite people, approve membership, and entrust additional Leaders without turning group administration into an enterprise workflow.

## Goals

- Keep group roles simple with `leader` and `member`.
- Allow any active member to invite people to a group through copyable invite codes.
- Require Leader approval before an invited person becomes a member.
- Show Leaders who requested to join and, when known, who invited them.
- Allow Leaders to propose group settings changes, including adding a Member as a Leader.
- Allow Leaders to propose removing a Member from a group through the same consensus workflow.
- Keep pending group settings changes private to current Leaders.
- Give Leaders a 24-hour window to approve or dispute a group settings change.

## Non-Goals

- Public group discovery.
- Immediate invite-code membership without review.
- Public display of group settings change discussions.
- Complex role templates or organization-wide permission systems.
- Deep-link invitation infrastructure before Vesper has an app link domain.

## User Stories

- As a Member, I can copy an invite code for my group so someone can request to join.
- As an invited person, I can enter an invite code and request access to the group.
- As a Leader, I can see pending join requests with requester and inviter display names when available.
- As a Leader, I can approve a join request and grant the new member access to the encrypted group key.
- As a Leader, I can reject a join request without exposing prayer content.
- As a Leader, I can open Group Settings from inside a group.
- As a Leader, I can propose changing whether requests publish immediately or wait for Leader approval.
- As a Leader, I can propose adding a Member as a Leader.
- As a Leader, I can propose removing a Member from the group.
- As a Leader, I can approve or dispute another Leader's proposed settings change.
- As a Member, I do not see pending, disputed, or cancelled group settings changes, including changes involving me.

## UX Notes

Use the term `Leader` in product copy and `leader` in stored role values. Avoid `admin`, `owner`, and `pastor` as product roles unless a future organization model introduces more granular role templates.

Invite codes should feel calm and practical. The current implementation generates copyable `VESPER-` codes with a seven-day default expiration and stores only a normalized code hash for lookup. The invite flow should explain that entering a code requests access and that a Leader will review the request. Avoid language that implies rejection is public or urgent.

Group Settings should be available inside a group only to Leaders. Settings changes should be quiet and private. Pending changes, approvals, and disputes are visible only in Leader-facing settings surfaces. Members should not receive notifications, badges, or status changes until a change takes effect.

Long-press menus should reveal secondary options without immediately applying access-control changes. On the home group list, long-pressing a group row opens a menu with `Pin`, `Share`, and `Leave`. In Group Settings, long-pressing an active Member row opens a menu with `Promote` and `Remove`; both create pending settings changes rather than changing membership immediately.

## Data Model

Use the canonical collections in [Firestore Schema](../../architecture/firestore-schema.md):

- `group_members` with roles `leader` and `member`.
- `invite_codes` for hashed copyable invite-code metadata.
- `join_requests` for invite-code membership requests.
- `group_settings_changes` for Leader-only settings change workflows.
- `group_keys` for encrypted group key delivery after membership approval.

The group creator is automatically created as an active `leader`. Approved invite-code join requests create or activate a `member` membership.

Group settings change records include type, proposer, target user when applicable, proposed setting values when applicable, status, creation time, expiration time, approvals, and disputes. A Member targeted for Leader access remains a `member` while the change is pending. A Member targeted for removal remains active while the change is pending and is marked `removed` only after the change is approved or expires without dispute.

## Security And Privacy

Invite codes and join requests must not contain prayer content. The backend may store membership metadata, invite routing metadata, timestamps, and role state, but it must never receive plaintext group keys or prayer content.

Approving a join request requires a Leader device to encrypt the active group key for the requester. Cloud Functions may validate workflow state, but they must not handle plaintext group keys.

Group settings change records must be readable only by current Leaders. Members, including a targeted Member, must not be able to read pending, disputed, cancelled, or expired settings change records.

## Offline Behavior

Users may view previously synced group membership state offline. Invite-code creation, join request approval, and group settings change decisions should require current server state before taking effect because they change access control or governance.

Queued governance writes should be treated carefully. If a user's role, membership status, or group key version changes before replay, the client should revalidate permissions before submitting.

## Acceptance Criteria

- A group creator becomes an active Leader automatically.
- Active Members can create copyable invite codes when the group allows member invites.
- Entering an invite code creates a join request, not membership.
- Leaders can see requester and inviter display names on join requests when both profiles are available.
- Approving a join request creates or activates Member access and encrypts the group key for that user.
- Rejecting a join request does not expose prayer content.
- A Leader can access Group Settings from inside a group.
- A Leader can propose changing the group's publishing policy.
- A Leader can propose adding an active Member as a Leader.
- A Leader can propose removing an active Member from the group.
- A Member proposed for Leader access remains a Member during the pending period.
- A Member proposed for removal remains active during the pending period.
- Pending settings changes are invisible to Members, including targeted Members.
- Any Leader dispute cancels the settings change and remains visible to Leaders.
- If all current Leaders approve before 24 hours, the settings change applies immediately.
- If 24 hours pass with no disputes, the settings change applies automatically.

## Open Questions

- Should invite codes support explicit usage limits beyond the current default expiration?
- Should future settings changes support grouped/batched changes, or should each change remain separate?
