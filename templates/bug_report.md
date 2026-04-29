---
name: Bug Report
about: Defect intake with reproduction, verification, design linkage, and stage hints for `/research`, `/plan`, `/build`, `/vqa`
labels: bug
---

<!--
BUG workflow: characterize → reproduce → isolate → fix → verify. Sections below mirror that so triage agents do not reinvent structure.
Stages: 🔍 Understand / reproduce → 📋 Isolate & plan fix → 🛠️ Implement → ✅ Verify & regression
-->

## Goal

<!--
One paragraph: acceptable resolution — restored behavior **or** intentional product/doc change tracked separately.
-->

---

## Summary

<!-- One brutal sentence engineers can skim in Slack / JIRA cards -->

-

## Severity & user impact *(triage hints)*

| | |
| --- | --- |
| **Who is affected** | <!-- personas / % of users --> |
| **Frequency** | <!-- always \| often \| intermittent \| rare --> |
| **Workaround exists?** | <!-- yes \| no \| partial --> |
| **Revenue / safety / compliance** | <!-- yes \| no \| note --> |

---

## Steps to reproduce

1. <!-- environment / account preconditions -->

2. <!-- action -->

3. <!-- observe -->

**Fastest reproduction path:**

<!-- Alternative one-liner for devs -->

---

## Expected vs actual

### Expected *(correct behavior)*

-

### Actual *(defect symptom)*

-

### Environment *(fill what you know)*

| | |
| --- | --- |
| **OS / device** | |
| **Browser / app version** | |
| **Branch / deployment** | |
| **Feature flags** | |

---

## Design reference *(for UI/visual bugs)*

| | |
| --- | --- |
| **Figma** | <!-- intended state — omit if N/A --> |
| **Node / frame** | |
| **Regression screenshot** *(optional)* | <!-- attach --> |

*N/A:* say **Does not apply — API / logic / infra bug**.*

---

## User story *(who loses when we leave this unfixed)*

<!--
As a [persona], I expect [behavior] because [business or trust reason].

Optional: related analytics or support-volume note.
-->

-

---

## Acceptance criteria *(fix verification)*

- [ ] Reproduction succeeds on `main` *(or nominated branch)* before fix
- [ ] After fix: expected behavior verified on **[platform list]**
- [ ] Automated tests *(if feasible)* cover regression at **[layer: unit/integration/e2e]**
- [ ] Accessibility / localization reviewed if UX surface changed
- [ ] Observability *(logs/alerts/dashboards)* updated if incidence was silent

<!-- Add product-specific bullets below -->

-

## Suspected cause *(optional)*

<!-- Engineer / agent hypothesis — avoids duplicate spelunking -->

-

## Blast radius / regression risk

<!-- Data migration, caches, CDN, downstream services, correlated features -->

-

---

## 🔍 Ready for `/research`

<!--
Questions that must land in **`research/`** before sizing:

-

-->

-

## 📋 Ready for `/plan`

<!--
Dependencies blocking fix:

-

-->

-

## 🛠️ Ready for `/build`

<!--
 Preconditions (flags, mocks, seeded data):

-

-->

-

---

## Additional context *(optional)*

<!-- Stack traces (**redacted**), HAR excerpts, Slack threads -->

-

## References *(optional)*

<!-- Related BUG/WO/Jira, incident links, RCA docs -->

-
