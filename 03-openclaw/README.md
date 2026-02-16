# OpenClaw Project Bootstrap

This directory contains the planning + Phase 1 scaffold for `03-openclaw`.

## Current Scope
- Telegram bot control plane with strict chat whitelist.
- Logseq-grounded RAG over `data/logseq/` with citations in answers.
- Manual reindex flow (full/incremental).
- Chrome automation with 1Password-assisted auth flow.
- Screenshot delivery to Telegram and local persistence in `data/screenshots/`.
- Continuous network traffic collection in main container via `vnstat` (`data/vnstat/` persisted).

## Files
- `REQUIREMENTS.md`: locked requirements and acceptance criteria.
- `PLAN.md`: phased delivery plan.
- `docker-compose.yml`: baseline services (`openclaw`, `qdrant`, `chrome`).
- `Dockerfile.openclaw`: custom main image layer (installs `vnstat`).
- `.env.example`: required environment variables template.
- `.gitignore`: local data/secret exclusions.

## Folder Layout
- `config/`: service config artifacts.
- `data/logseq/`: notes source corpus (user-managed).
- `data/vector/`: vector store data.
- `data/browser/`: browser runtime artifacts.
- `data/screenshots/`: stored browsing screenshots.
- `data/vnstat/`: persistent vnStat database.
- `backup/`: backups and snapshots.

## Phase 1 Status
- Directory skeleton created.
- Compose baseline created and syntax-validated.
- Main OpenClaw service now builds a custom image that includes `vnstat`.
- Main OpenClaw startup runs `vnstatd` in background for regular stats collection.
- Local `.env` can be created from template:
  - `cp .env.example .env`

## Next Step
- Phase 2: implement Telegram bot service wiring and whitelist enforcement.
