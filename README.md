# Finance Brokers – Document Collection (AU Broker Flow)

An AI agent system that runs the **document collection and verification** stage of mortgage loan processing for Australian mortgage brokers, from the moment a sales meeting ends to a broker-review-ready application.

> **Status:** MVP build in progress. The core pipeline (WF-001 to WF-010) is built and verified end to end on Telegram. WhatsApp and the broker human-checkpoint steps are still planned.
> **Repo visibility:** Private. This is the working source of truth for the project.

---

## The problem

After a sales meeting, brokers and their processors spend hours per file messaging borrowers a document checklist, chasing missing items, reading every document by hand, and cross-checking names, addresses and dates across files. It is repetitive, error-prone and limits how many files a broker can run at once.

## The solution

Coordinated AI agents and rule-based workflows that talk to the borrower, collect and classify documents, extract and verify the data, cross-check consistency across all documents, and then either clear the file or flag exactly what is wrong. **The broker always makes the final call.**

**What it does not do:** make lending or credit decisions, submit applications to lenders, replace broker judgement, or give financial or legal advice.

Full product definition: [Founder_MVP_PRD_Mortgage_Broker_AI_Agent.md](Founder_MVP_PRD_Mortgage_Broker_AI_Agent.md)

---

## How it works

```
Borrower (Telegram live, WhatsApp planned)
        ↓
WF-001 Conversation Manager   (chat, checklist, document intake)
        ↓
WF-002 Workflow Manager       (metadata-driven orchestrator, runs steps in order)
        ↓
WF-004 OCR  →  WF-005 Document Intelligence  →  WF-006 Verification
        ↓
WF-007 Cross Validation  →  WF-008 Decision
        ↓
WF-010 Broker Notification  →  Broker reviews and submits (human)
        ↑
WF-009 Reminder (chases borrower)  ·  WF-011 Checklist follow-up  ·  WF-012 Status notifier
```

The workflow engine is data-driven. A loan workflow is stored in Postgres as definitions, stages, steps and transitions. WF-002 reads those tables and calls each step's agent in turn. See [Architecture.md](Architecture.md) and [Architectural Decision Record 001.txt](Architectural%20Decision%20Record%20001.txt) and [002](Architectural%20Decision%20Record%20002.txt).

### Workflows

| ID | Workflow | Type | What it does |
|---|---|---|---|
| WF-001 | Conversation Manager | AI agent | Talks to the borrower, sends the checklist, validates and uploads documents, hands off to OCR |
| WF-002 | Workflow Manager | Orchestrator | Recursive, metadata-driven engine that executes workflow steps in sequence |
| WF-003 | Document Intake | Rule-based | Standalone intake build. **Retired from the live pipeline**, as WF-001 now owns intake |
| WF-004 | OCR Agent | AI (GPT-4.1 Vision) | Transcribes images and PDFs (PDFs pre-converted via ConvertAPI) |
| WF-005 | Document Intelligence | AI (GPT-4.1) | Extracts structured fields (name, DOB, address, document number, expiry, issuer) |
| WF-006 | Verification | Rule-based | Per-document completeness and expiry checks |
| WF-007 | Cross Validation | Rule-based | Fuzzy-matches names and addresses and exact-matches DOB across documents |
| WF-008 | Decision Agent | Rule-based | PASSED leads to broker go-ahead. FAILED leads to manual review with reasons |
| WF-009 | Reminder Agent | Rule-based | Sends borrower reminders and resets the checklist item |
| WF-010 | Broker Notification | Rule-based | Emails the broker with an approved or action-needed message |
| WF-011 | Checklist Follow-up | Scheduled | Periodic checklist chase (every 10 minutes) |
| WF-012 | Status Notifier | Rule-based | Status updates to the borrower |

Per-workflow build notes, bugs found and fixes: the `WF0xx_status.md` files.

---

## Tech stack

- **Orchestration:** n8n
- **Database and storage:** Supabase (Postgres, file storage)
- **AI:** OpenAI GPT-4.1 (Vision for OCR, language model for extraction and conversation)
- **Channels:** Telegram (live), WhatsApp Business via Meta (in progress, see [WhatsApp_Meta_Handoff.md](WhatsApp_Meta_Handoff.md))
- **Email:** Gmail
- **PDF conversion:** ConvertAPI

---

## Repository layout

| Path / pattern | Contents |
|---|---|
| `0xx_*.sql` | Numbered database migrations for the workflow engine (027 to 055) |
| `* Migration Table.sql`, `create_*.sql` | Core table migrations (borrowers, brokers, documents, OCR, verification, cross-validation, decisions, agents, reminders and others) |
| `WF0xx *.json` | Exported n8n workflows |
| `WF0xx_status*.md` | Status, bugs and decisions per workflow |
| `*System Prompt.txt`, `WF003_..._Spec.txt` | Agent system prompts and operating specs |
| `Shared Payload & Schemas.txt` | Contracts shared between workflows |
| `Visual Tables Schema 23rd July 26.txt` | Schema overview |
| `Architecture.md`, `Architectural Decision Record 00x.txt` | Architecture and decisions |
| `Founder_MVP_PRD_*.md` | Product requirements |
| `data_quality_correction.md` | Data quality notes |

---

## Setup notes

- **Credentials are not in this repo.** Exported workflows contain placeholders such as `{{SUPABASE_SERVICE_ROLE_KEY}}` and `{{SUPABASE_SECRET_KEY}}`. After importing a workflow into n8n, replace them with n8n credentials or environment variables.
- Apply the SQL migrations to a Supabase/Postgres project in numeric order, starting with the core tables and then `027` onwards.
- **Never commit real keys, tokens or borrower data.** Re-check exported workflow JSON for secrets before every commit.

## Testing discipline

1. In n8n, always **Save and Publish** before testing. The recursive self-call only runs the published version.
2. Confirm results with a direct database query (`workflow_step_executions`, `workflow_instances`). An n8n "Succeeded" badge only means no node errored.
3. Use `workflow.reset_instance_for_test(instance_id)` (migration 055) to reset a stuck test instance.

## Known gaps / roadmap

- Broker review and application submission are human checkpoint steps. The orchestrator does not yet pause and resume on them (design in [Architecture.md](Architecture.md)).
- WhatsApp channel is pending Meta account approval. WhatsApp is currently a placeholder in WF-001.
- Assumptions in the PRD still need validation with target brokers.

---

© AU Broker Flow. All rights reserved. Proprietary and confidential.
