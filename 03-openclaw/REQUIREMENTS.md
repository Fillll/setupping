# OpenClaw Requirements (Draft v0.3)

## 1. Objective
Create a production-ready `OpenClaw` deployment in this repository that can:
- communicate with you via Telegram,
- answer questions using your Logseq notes through vector semantic search,
- browse websites in Chrome (with 1Password-assisted access) and send screenshots back via Telegram.

## 2. Functional Requirements
1. Provide a reproducible setup workflow for `OpenClaw` in `03-openclaw`.
2. Implement Telegram bot integration for inbound commands and outbound responses.
3. Enforce Telegram whitelist controls: only configured chat IDs are accepted for inbound messages.
4. Silently ignore non-whitelisted chats; do not process commands and do not return details.
5. Create and use a `data/logseq/` directory as the source-of-truth notes corpus.
6. Build and maintain a vector index over `data/logseq/` for semantic retrieval.
7. Ensure note-question answers are grounded in note content only; responses must be based on retrieved notes.
8. Include explicit note citations/excerpts in each notes-based response.
9. Provide manual reindex operations (full and incremental) for updated notes.
10. Enable deep Chrome-based browsing automation (login + multi-step actions) for supported tasks.
11. Support secure use of 1Password credentials for website access during browser automation.
12. Capture and send browsing screenshots to approved Telegram chats.
13. Persist screenshots in `data/screenshots/` for later review.
14. Provide operational commands for start, stop, restart, logs, backup, restore, and reindex.
15. Include a concise `SETUP_SUMMARY.md` (not committed) with credentials, URLs, whitelist IDs, and verification results.

## 3. Non-Functional Requirements
1. Reproducible: setup should run from clean machine state with documented prerequisites.
2. Secure-by-default: secrets in `.env` or equivalent, never committed.
3. Privacy-preserving: no plaintext storage of 1Password master credentials.
4. Maintainable: key settings centralized and documented.
5. Observable: health checks and diagnostics for bot, index, and browser subsystems.
6. Recoverable: backup and restore flow documented and tested.
7. Traceable: logs should capture request flow at a level useful for debugging while avoiding secret leakage.

## 4. Constraints
1. Must live under `/home/fil/setupping/03-openclaw`.
2. Must be compatible with current repository conventions.
3. Must avoid committing secrets or machine-specific sensitive data.
4. `data/logseq/` must be treated as user-owned content and preserved across updates.
5. Any browser automation requiring authenticated access must use user-provided secure credential flow.

## 5. Assumptions (Need Confirmation)
1. `OpenClaw` will be containerized (Docker Compose preferred).
2. Deployment target is the same Raspberry Pi / home-lab environment.
3. Telegram bot token and whitelist chat IDs will be provided via environment configuration.
4. 1Password integration will use a supported CLI/session model (not hardcoded credentials).

## 6. Out of Scope (Initial Phase)
1. Advanced HA/cluster deployment.
2. Multi-region failover.
3. Full CI/CD automation beyond local reproducible setup.
4. Broad internet-facing multi-user access model beyond whitelisted Telegram usage.

## 7. Acceptance Criteria
1. A new user can follow docs and launch the stack successfully.
2. Telegram bot receives messages only from whitelisted chat IDs and responds correctly.
3. Non-whitelisted chat messages are blocked or ignored as configured.
4. `data/logseq/` content is indexed and semantic queries return note-grounded answers.
5. Reindex workflow updates retrieval results after note changes.
6. Chrome browsing task can run and return at least one screenshot to a whitelisted Telegram chat.
7. Authenticated website access via 1Password-assisted flow is documented and validated.
8. Backup/restore procedure is documented and passes a basic test.
9. Notes answers include citations/excerpts tied to retrieved Logseq sources.
10. Screenshot artifacts are stored in `data/screenshots/` and delivered to whitelisted Telegram chats.
11. Setup summary captures final working state and key credentials/URLs without exposing protected secrets in git.
