# Simplified Groups And Request Composer

## Problem

Users need to share prayer requests with one or more trusted groups quickly from the centered bottom request action, while Leaders need enough group administration to manage trust within the `Groups` tab without heavy governance workflows.

## Goals

- Provide a centered bottom `+` action for creating prayer requests.
- Let users choose one, many, or all eligible groups before submitting a request.
- Encrypt one request per selected group using that group's active key.
- Keep group administration to Leader/Member roles, join requests, reports, and admin history.
- Keep group creation, joining, administration, and group-specific feeds inside the `Groups` tab.
- Avoid approval queues, permission matrices, and consensus workflows in the MVP.
- Keep all request content unreadable to Firebase and Cloud Functions.

## Non-Goals

- Public posting.
- Public group discovery.
- Cross-group global backend feeds.
- Group-level request approval policies in the MVP.
- Shared multi-group plaintext request records.
- Custom role templates.

## User Stories

- As a user, I can tap the centered bottom `+` action from either tab to create a prayer request.
- As a user, I can see the groups where I am an active member.
- As a user, I can select groups with checkboxes.
- As a user, I can choose `Select All` to submit to every eligible group.
- As a user, I see how many groups are selected before submitting.
- As a user, I cannot submit until at least one group is selected.
- As a user, I get calm partial-success feedback if some group submissions fail.
- As a Leader, I can approve join requests.
- As a Leader, I can promote, demote, or remove members with confirmation.
- As a Leader, I can review reports and remove inappropriate requests.

## UX Notes

The centered bottom `+` action should be available across the signed-in app and labeled for accessibility as `Submit prayer request` or `Create prayer request`. It should be visually clear without overpowering the prayer-book reading experience. It is a primary action, not a third tab, and should not show a selected navigation state.

The bottom app bar should show `Pray` on the left, the centered `+` request action, and `Groups` on the right. Group creation, joining, invite codes, administration, and group-specific request feeds belong under `Groups`.

The group selector should make audience selection explicit. Each group row should include a checkbox, group name, and optional quiet metadata. The `Select All` row should clearly indicate checked, unchecked, or mixed state where supported.

If no group is selected, use calm validation copy:

```text
Choose at least one group to share this request.
```

If some group submissions fail, use calm partial-success copy:

```text
Shared with some groups. You can retry the others.
```

## Data Model

Use the canonical collections in [Firestore Schema](../../architecture/firestore-schema.md):

- `prayer_requests` for one encrypted request per selected group.
- `group_members` to determine eligible active groups.
- `group_keys` to encrypt each request to the selected group's active key.
- `request_reports` for metadata-only reports.
- `audit_events` for metadata-only admin history.

Do not create a shared multi-group request document. Do not store a plaintext list of selected groups as part of the request content. If local draft continuity is needed, store local encrypted draft metadata.

## Security And Privacy

The request composer must encrypt request content separately for each selected group. The backend receives only ciphertext, nonce, algorithm, key version, group ID, timestamps, status, and other non-sensitive metadata.

Cloud Functions may validate membership and fanout generic notifications, but must not receive plaintext request title, body, tags, summaries, private notes, or personal prayer content.

Notifications for submitted requests must use generic copy and must not include request text or content-derived summaries.

## Offline Behavior

When offline, the composer may allow drafting if group keys are locally available. Multi-group submission should queue one encrypted pending write per selected group.

On replay, each group write should revalidate membership and active key version. If the user lost access to a selected group before replay, that group write is blocked while other eligible group writes may proceed.

## Acceptance Criteria

- The signed-in bottom app bar includes a centered `+` action for creating a prayer request.
- The centered `+` action opens the request composer from either `Pray` or `Groups`.
- The composer lists active groups where the user is a member.
- Each group can be selected with a checkbox.
- `Select All` selects all eligible groups.
- The composer shows selected-count feedback.
- Submission is blocked until at least one group is selected.
- Submitting to multiple groups creates separate encrypted request documents.
- A partial failure does not undo successful group submissions.
- Request plaintext is never sent to Firestore, Cloud Functions, notifications, logs, analytics, or crash reporting.
- Group administration uses only `Leader` and `Member` roles.
- Group creation, joining, administration, and group-specific feeds are contained in the `Groups` tab.
- Last-Leader demotion and removal are blocked.

## Open Questions

- Should the composer remember the user's last selected group set locally?
- Should `Select All` include archived or muted groups if those states are added later?
- Should partial retry preserve the same encrypted plaintext locally or require the user to confirm before retry?
