# Moderation operations

Review the moderator queue every day. Aim to triage safety reports within 24 hours. The support inbox must be monitored and staffed before launch.

1. Open More → Moderation using a server-assigned moderator account. Review reported content, its context, and the contributor’s prior conduct.
2. Reject abusive submissions or remove abusive published reviews. Resolve linked reports after action; dismiss unfounded reports with an internal rationale.
3. Use Block Contributor for repeated or serious abuse. The backend rejects new reviews, edits, reports, and non-support community submissions; existing published reviews from that contributor are hidden. Support appeals and account deletion remain available.
4. Review appeals using the monitored public support address or in-app support queue. Unblock from the blocked-contributors list when appropriate. Unblocking can make previously approved reviews visible again, so remove harmful reviews separately.
5. Escalate credible safety/privacy issues promptly. Do not copy sensitive training material or personal data into public responses. Retain only the information needed to resolve the report.

Only moderators can read/modify bans. Ordinary users cannot grant subscription overrides or moderation roles. Provision roles through the restricted administrative database workflow, never from client UI.

Before release, test the production sequence with a controlled contributor: submit → report → moderate → block → rejected contribution → appeal → unblock. Delete the controlled accounts and verify associated content is removed. Local integration coverage does not replace this authenticated production check.

Requirement reference: https://developer.apple.com/app-store/review/guidelines/#user-generated-content
