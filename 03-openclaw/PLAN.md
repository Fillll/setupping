# OpenClaw Implementation Plan (Draft v0.3)

## Phase 0: Locked Decisions
- Non-whitelisted Telegram chats are silently ignored.
- Notes answers include citations/excerpts from retrieved sources.
- Reindexing is manual (full and incremental commands).
- Browsing MVP includes deep workflows (login + multi-step actions).
- Screenshots are persisted in `data/screenshots/` and also sent via Telegram.
- Exit criteria: reflected in config templates and command contracts.

## Phase 1: Project Skeleton
- Create folder structure:
  - `config/`
  - `data/logseq/`
  - `data/vector/`
  - `data/browser/`
  - `data/screenshots/`
  - `backup/`
- Add `.env.example` and `.gitignore` entries.
- Add baseline `docker-compose.yml` and documentation files.
- Exit criteria: skeleton validates and is internally consistent.

## Phase 2: Telegram Control Plane
- Implement bot service configuration (token, polling/webhook mode).
- Implement whitelist enforcement using configured chat IDs.
- Implement command routing for core actions (status, ask, browse, screenshot).
- Add tests or verification script for whitelist behavior.
- Exit criteria: only whitelisted chats can trigger actions.

## Phase 3: Notes RAG Pipeline
- Mount `data/logseq/` as notes source.
- Implement ingestion/chunking/embedding pipeline.
- Store vectors in configured vector backend.
- Implement retrieval + grounded response flow restricted to note corpus.
- Add manual full and incremental reindex commands.
- Exit criteria: semantic note Q&A works and updates after reindex.

## Phase 4: Browser Automation + Screenshots
- Integrate Chrome automation runtime.
- Integrate secure 1Password-assisted credential flow.
- Implement screenshot capture commands, Telegram delivery, and local persistence in `data/screenshots/`.
- Add failure handling and timeout controls for browser tasks.
- Exit criteria: browsing workflow returns screenshots in Telegram for approved chats.

## Phase 5: Security and Operations
- Harden secret management and environment configuration.
- Add health checks and operational runbook commands.
- Add backup/restore for configs, vectors, and relevant state.
- Exit criteria: operator can recover and operate stack reliably.

## Phase 6: Verification and Summary
- Execute verification checklist across Telegram, RAG, and browser flows.
- Record final values in `SETUP_SUMMARY.md` (kept out of git).
- Final documentation cleanup.
- Exit criteria: reproducible setup confirmed end-to-end.

## Risks
1. Browser automation + authenticated sessions may be brittle across websites.
2. Incorrect whitelist handling could expose bot actions.
3. Retrieval quality may degrade with poor chunking/index configuration.
4. Resource constraints on target host (CPU/RAM/storage).

## Mitigations
1. Start with narrow MVP browsing flows and explicit task contracts.
2. Add explicit whitelist tests and deny-by-default behavior.
3. Validate indexing/retrieval with representative Logseq queries early.
4. Measure resource usage and pin versions once baseline is stable.

## Immediate Next Step
- Scaffold Phase 1 files and compose services based on the locked decisions.
