# 0035 — Schools, students & education

- **Status:** ready
- **Milestone:** [M14 — Schools & Community Life](../roadmap.md#m14--schools--community-life)
- **Depends on:** 0030, 0034

## Goal
Trade some immediate workforce availability for a visible, lasting adult production benefit.

## Context
Children currently enter the workforce at 10. Preserve a viable uneducated path and existing housing/family rules; schooling must not strand a cohort permanently outside the labor pool.

## Scope
- Add a constructible school, teacher profession, finite student slots, attendance, and student life stage in population/profession panels.
- At working age, enroll eligible settlers when a staffed reachable slot is available; otherwise they become uneducated workers. Students eat/rest normally and do not work or haul.
- Graduation follows a fixed documented amount of attended school time, with a maximum school-leaving age. Teacher loss/closure pauses progress; slot loss permits transfer, and maximum age always releases the student to work.
- Apply education as a documented bounded work-rate bonus using existing work-speed handling, including crafting, farming, and building; avoid duplicating tool/elder modifiers.
- Persist enrollment/progress/education and integrate capacity/coverage feedback, seasonal art, and long-run cohort checks.

## Out of scope
- Research points, universities, compulsory education, and education inherited by children.

## Acceptance criteria
- [ ] A cohort enrolls, attends, graduates, and joins work in a repeatable long-run scenario.
- [ ] Unavailable schooling and teacher loss/demolition have the defined fallback; no settler remains a student past the maximum age.
- [ ] Equal-tool educated/uneducated workers exhibit the documented work-rate difference.
- [ ] Population and labor counts exclude students consistently; survival and family replacement remain possible.
- [ ] Round-trip checks cover active students; art/UI and error-free headless behavior are verified.

## Open questions
- None; document school capacity, attendance duration, leaving age, and bonus before balancing the cohort test.
