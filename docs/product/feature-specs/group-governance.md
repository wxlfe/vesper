# Group Governance

## Problem

Prayer groups need a simple way to invite people, approve membership, and entrust additional Leaders without turning group administration into an enterprise workflow.

## Goals

- Keep group roles simple with `leader` and `member`.
- Allow any active member to invite people to a group through copyable invite codes.
- Require Leader approval before an invited person becomes a member.
- Show Leaders who requested to join and, when known, who invited them.
- Allow Leaders to nominate Members to become Leaders.
- Keep pending Leader promotions private to current Leaders.
- Give Leaders a 24-hour window to approve or dispute a promotion.

## Non-Goals

- Public group discovery.
- Immediate invite-code membership without review.
- Public display of Leader promotion discussions.
- Complex role templates or organization-wide permission systems.
- Deep-link invitation infrastructure before Vesper has an app link domain.

## User Stories

- As a Member, I can copy an invite code for my group so someone can request to join.
- As an invited person, I can enter an invite code and request access to the group.
- As a Leader, I can see pending join requests with the requester and inviter context.
- As a Leader, I can approve a join request and grant the new member access to the encrypted group key.
- As a Leader, I can reject a join request without exposing prayer content.
- As a Leader, I can nominate a Member to become a Leader.
- As a Leader, I can approve or dispute another Leader's nomination.
- As a Member, I do not see pending, disputed, or cancelled Leader promotions, including promotions involving me.

## UX Notes

Use the term `Leader` in product copy and `leader` in stored role values. Avoid `admin`, `owner`, and `pastor` as product roles unless a future organization model introduces more granular role templates.

Invite codes should feel calm and practical. The invite flow should explain that entering a code requests access and that a Leader will review the request. Avoid language that implies rejection is public or urgent.

Leader promotion should be quiet and private. Pending promotions, approvals, and disputes are visible only in Leader-facing group management surfaces. Members should not receive notifications, badges, or status changes until a promotion takes effect.

## Data Model

Use the canonical collections in [Firestore Schema](../../architecture/firestore-schema.md):

- `group_members` with roles `leader` and `member`.
- `invite_codes` for hashed copyable invite-code metadata.
- `join_requests` for invite-code membership requests.
- `leader_promotions` for Leader-only promotion workflows.
- `group_keys` for encrypted group key delivery after membership approval.

The group creator is automatically created as an active `leader`. Approved invite-code join requests create or activate a `member` membership.

Leader promotion records include nominee, nominator, status, creation time, expiration time, approvals, and disputes. The nominee remains a `member` while the promotion is pending.

## Security And Privacy

Invite codes and join requests must not contain prayer content. The backend may store membership metadata, invite routing metadata, timestamps, and role state, but it must never receive plaintext group keys or prayer content.

Approving a join request requires a Leader device to encrypt the active group key for the requester. Cloud Functions may validate workflow state, but they must not handle plaintext group keys.

Leader promotion records must be readable only by current Leaders. Members, including the nominee, must not be able to read pending, disputed, cancelled, or expired promotion records.

## Offline Behavior

Users may view previously synced group membership state offline. Invite-code creation, join request approval, and Leader promotion decisions should require current server state before taking effect because they change access control or governance.

Queued governance writes should be treated carefully. If a user's role, membership status, or group key version changes before replay, the client should revalidate permissions before submitting.

## Acceptance Criteria

- A group creator becomes an active Leader automatically.
- Active Members can create copyable invite codes when the group allows member invites.
- Entering an invite code creates a join request, not membership.
- Leaders can see the requester and inviter on join requests when both are known.
- Approving a join request creates or activates Member access and encrypts the group key for that user.
- Rejecting a join request does not expose prayer content.
- A Leader can nominate an active Member for Leader promotion.
- The nominee remains a Member during the pending period.
- Pending promotions are invisible to Members, including the nominee.
- Any Leader dispute cancels the promotion and remains visible to Leaders.
- If all current Leaders approve before 24 hours, the nominee becomes a Leader immediately.
- If 24 hours pass with no disputes, the nominee becomes a Leader automatically.

## Open Questions

- Should invite codes have default expiration or usage limits?
- Should disputes require a structured reason, freeform text, or no reason?
- Should a Leader who nominated a Member count as an approval automatically?
