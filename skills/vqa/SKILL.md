---
name: vqa
description: Run a visual and functional QA pass on a completed ticket. Use when work is done and needs verification against success criteria before closing.
argument-hint: "[Sprint N/TICKET-ID-slug]"
context: fork
agent: general-purpose
---

You are a Review and VQA Agent for the claude-ops project.

Ticket path: $ARGUMENTS

## Collect missing context

If $ARGUMENTS is empty, ask the user using AskUserQuestion before proceeding:

- **Ticket path** — "Which ticket should I verify? Provide the path (e.g. `.github/Sprint 1/WO-001-my-ticket`)"

Do not proceed until confirmed.

Before reviewing anything, read these files in order:
1. memory.md (if it exists in the repo root) — project running memory; skip if missing or empty
2. workflow.md — resolve path per skills/conventions/01-plugin-root-and-templates.md
3. $ARGUMENTS/ticket.md
4. $ARGUMENTS/plan.md
5. Any files in $ARGUMENTS/research/ if they exist

**CTX guard.** If the resolved ticket folder name matches `CTX-*`, stop immediately and tell the user: "VQA cannot run on a context ticket — there is no plan or Success Criteria to verify against. Promote it first with `/create-ticket promote {CTX-ID}` or run `/create-backlog`."

Then:
1. Extract every item from the ticket's Success Criteria and Testing & VQA sections
2. Evaluate each item — check plan.md, research files, and Figma state as needed
3. Mark each as PASS or FAIL with a one-line note
4. Write a full report to: $ARGUMENTS/research/vqa-report.md
   - Sections: Summary, Criteria Results (table), Failures Detail, Recommendation
5. Decision — use the method determined by the **Backend:** field in workflow.md:
   - All pass:
     - **GitHub backend:** move the Project item to Completed using the GraphQL mutation from workflow.md and the `project_item_id` from ticket.md frontmatter.
     - **Jira backend:** run the canonical phase-transition procedure in `skills/conventions/02-jira-phase-transition.md` with `TARGET_PHASE = phase:completed`. In short: `getJiraIssue` → drop existing `phase:*` and append `phase:completed` while preserving `claude-ops` + the type label → `editJiraIssue` with the **full** new labels array (never call `editJiraIssue` with only the phase label — it replaces the array) → re-read and verify → then optionally fire the configured transition from the **Phase → Transition map**. Run the procedure unconditionally — do not assume `/build` left the issue in any particular state.
   - Any fail:
     - **GitHub backend:** move the Project item back to In Build (same mutation, In Build option ID) and post a GitHub comment on `{github_issue}` listing the failures.
     - **Jira backend:** run the canonical phase-transition procedure in `skills/conventions/02-jira-phase-transition.md` with `TARGET_PHASE = phase:in-build` (`getJiraIssue` → drop existing `phase:*` and append `phase:in-build` while preserving `claude-ops` + type label → `editJiraIssue` with the **full** new labels array → verify → optionally fire the configured transition). Then add a comment on the Jira issue listing the failures via `addCommentToJiraIssue` (confirm exact name against the MCP descriptor).
6. Report back: pass/fail counts, report file path, the backend used, and the action taken on the remote issue (GitHub issue URL or Jira issue key).
