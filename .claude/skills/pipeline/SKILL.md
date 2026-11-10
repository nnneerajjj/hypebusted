---
name: pipeline
description: Run the multi-agent build pipeline (plan, tests, code, review, QA) for a feature requirement with no human input between stages.
disable-model-invocation: true
argument-hint: <feature requirement>
---

Run the full pipeline for this requirement: $ARGUMENTS

You are the orchestrator. Spawn each stage as a separate agent via the Agent tool (subagent_type = the agent name). Every agent starts with no memory, so pass it everything it needs in the prompt. Never do a stage's work yourself. Do not pause for the user between stages, except for step 1's open questions.

Isolation rule: the **reviewer** and **tester** get only the requirements/plan and the instruction to inspect the working tree. Never give them the coder's report or reasoning.

1. **planner** (plan mode) with the requirement. If it returns open questions, ask the user once with AskUserQuestion, then re-run the planner with the answers. Keep the final requirements + plan text.
2. **test-writer** with requirements + plan. Confirm tests fail for the right reason.
3. **coder** with plan + test file paths. 
4. **planner** (verify mode) with plan + coder report. If CHANGES REQUIRED, send the fixes back to **coder** and re-verify. Max 3 rounds.
5. **reviewer** with requirements only. If CHANGES REQUIRED, send the findings to **coder**, then run a **fresh** reviewer again. Max 3 rounds.
6. **tester**. If FAIL, send failures to **coder**, then re-run reviewer and tester. Max 2 rounds.
7. If any loop hits its cap, stop and report what is unresolved instead of continuing.

Finish with a short summary: what was built, files changed, how many fix rounds each stage took, any reviewer findings you chose not to apply and why, and the exact URL/steps for the user to check in the browser. Do not commit or push; the user decides after the browser check.
