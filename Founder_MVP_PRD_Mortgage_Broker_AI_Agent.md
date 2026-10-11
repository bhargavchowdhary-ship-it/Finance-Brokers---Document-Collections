# Founder / MVP PRD
## Mortgage Broker – Loan Processing AI Agent
**Market:** Australian Mortgage Brokers | **Stage:** Build in progress (post-architecture, mid-implementation)

---

## 1. Executive Summary

**Product:** An AI agent system that runs the post-sales-meeting loan-processing workflow for Australian mortgage brokers — from document checklist to broker-review-ready application.

**Target Customer:** Australian mortgage brokers and small brokerages who lose hours per file chasing, checking, and cross-checking borrower documents.

**Problem:** Once a broker finishes a sales meeting, the highest-effort, lowest-value work begins — sending checklists, chasing borrowers, manually reading documents, and manually cross-checking names/addresses/dates across files. This is repetitive, error-prone, and eats broker time that should go to sales and lender relationships.

**Solution:** A set of coordinated AI agents (Conversation, Workflow Manager, Document Intake, OCR, Document Intelligence, Verification, Cross-Validation, Decision, Reminder, Broker Notification) that talk to the borrower, collect and classify documents, extract and validate data, cross-check consistency across all documents, and either clear the file for submission or flag exactly what's wrong — with the broker always making the final call.

**Core Value Proposition:** The broker stops doing document admin. The AI does the collection, checking, and chasing; the broker only reviews exceptions and gives the final sign-off.

**MVP Objective:** Prove that a broker will hand off borrower document collection and verification to the AI agent for a real applicant, and trust its "ready for submission" signal enough to act on it without re-doing the checking themselves.

> **We are building an AI agent operations layer for Australian mortgage brokers, to remove manual document collection and verification work between sales meeting and application submission.**

---

## 2. Problem

### Current Problem
After the sales meeting, the broker (or their processor) manually messages the borrower with a document checklist, waits, chases missing items, opens every file to check details, and manually compares names/addresses/ID numbers/expiry dates across documents before an application can go to a lender. This is done per borrower, per document, every single time.

### Pain Points
1. Chasing borrowers for documents consumes broker/staff time daily.
2. Manual document reading is slow and inconsistent between staff.
3. Manual cross-checking (name/address/DOB/expiry across multiple docs) is where errors slip through.
4. No consistent audit trail of what was checked and when.
5. Processing speed directly limits how many files a broker can run at once.

### Business Impact
- **Broker time:** Hours per file spent on admin, not selling or advising.
- **Processing speed:** Bottlenecked by manual chase-and-check cycles.
- **Operational workload:** Scales linearly with file volume — no leverage.
- **Customer experience:** Borrowers get inconsistent follow-up and unclear status.
- **Errors/rework:** Inconsistent data caught late costs resubmissions and delay.

*(Assumption — requires validation with target brokers: the above pains are ranked in this order of severity.)*

---

## 3. Target Customer & Users

### Primary Customer
Australian mortgage brokers / small-to-mid mortgage brokerages.

### Primary Users

| Persona | What they do | What they need | Biggest pain point | Desired outcome |
|---|---|---|---|---|
| Mortgage Broker | Sells, advises, submits to lenders | To submit clean, complete files fast | Manual chasing and checking eats their day | Files arrive ready to submit, with exceptions clearly flagged |
| Loan Processor / Support Staff | Executes document collection & checking | A reliable, repeatable process | Repetitive manual work, inconsistent checklists | System does the repetitive work; they handle only exceptions |

### Secondary User
**Borrower** — receives checklist, uploads documents, responds to follow-ups. Wants a simple, low-friction way to know what's needed and confirm it's done.

---

## 4. Current vs Future Workflow

### Current Workflow
```
Sales Meeting
↓
Document Checklist (manual)
↓
Borrower Sends Documents (email/WhatsApp/in person)
↓
Broker/Staff Checks Documents (manual read)
↓
Missing Documents (manual tracking)
↓
Follow-ups (manual)
↓
Review
↓
Data Extraction (manual)
↓
Validation (manual cross-check)
↓
Application Preparation
```

### Future Workflow
```
Sales Meeting
↓
Broker Assigns Borrower to AI Agent
↓
AI Starts Conversation & Sends Checklist
↓
Borrower Uploads Documents
↓
AI Classifies & OCR-Extracts
↓
AI Verifies (per-document checks: name, DOB, expiry, address)
↓
AI Cross-Validates (consistency across all documents)
↓
AI Identifies Missing / Conflicting Information
↓
AI Follows Up With Borrower Automatically
↓
Human Escalation Where Required
↓
Broker Reviews Exceptions Only
↓
Application Ready for Submission
```

**What work is removed from the broker:** sending checklists, tracking who's sent what, manually reading every document, manually cross-checking every field, and manually chasing missing items. The broker's remaining job is judgment calls and final sign-off.

---

## 5. Product Solution

### What the Product Does
Runs the full document-collection-to-verification pipeline autonomously per borrower: communicates, collects, classifies, extracts, verifies, cross-validates, follows up, and tells the broker when a file is ready — or exactly what's wrong.

### What the Product Does NOT Do
- Does not make lending or credit decisions.
- Does not submit applications to lenders.
- Does not replace broker judgment on exceptions.
- Does not give financial or legal advice to borrowers.

### Core Value Proposition
Turn document collection and verification from broker-hours-per-file into a background process the broker only touches at the exception and final-review stage.

### Why AI?
Reading and comparing unstructured documents (IDs, payslips, bank statements) at borrower-conversation speed is a language + extraction + reasoning problem — exactly what an LLM-based agent pipeline is built for. The goal is not "AI everywhere"; it's removing the two most repetitive human bottlenecks: talking to borrowers, and checking documents.

---

## 6. Product / AI Agent Architecture

```
Borrower
   ↓
Communication Layer (Telegram live; WhatsApp planned)
   ↓
Conversation Manager
   ↓
Workflow Manager (orchestrator — metadata-driven)
   ↓
Document Processing
   ├── Document Intake
   ├── OCR Agent
   ├── Document Intelligence (structured extraction)
   ├── Verification (per-document rule checks)
   └── Cross-Validation (consistency across documents)
   ↓
Decision Agent (ready / needs more documents / manual review)
   ↓
Reminder Agent (automated follow-up)
   ↓
Broker Notification
   ↓
Broker Review → Application Ready
```

| Component | Purpose | Key Responsibility |
|---|---|---|
| Conversation Manager | Talks to the borrower | Intent detection, routing, never invents status |
| Workflow Manager | Orchestrates the whole pipeline | Stage/step sequencing, retries, escalation — never does agent work itself |
| Document Intake | Receives & logs incoming files | File storage, checklist tracking |
| OCR Agent | Reads document content | Raw text/data extraction |
| Document Intelligence | Structures extracted data | Maps raw OCR into typed fields (name, DOB, expiry, address) |
| Verification | Checks a single document | Field completeness, expiry validity |
| Cross-Validation | Checks across documents | Name/address/DOB/expiry consistency across all borrower documents |
| Decision Agent | Rule-based gate | APPROVED / MORE_DOCUMENTS_REQUIRED / MANUAL_REVIEW |
| Reminder Agent | Chases missing items | Automated borrower follow-up |
| Broker Notification | Closes the loop | Notifies broker of outcome, ready-for-review or exception |

Underlying engine: a **metadata-driven workflow model** (workflow_definitions → stages → steps → instances → executions in the database), so adding or changing a step is a database row change, not a rebuilt n8n workflow.

---

## 7. MVP Definition

### MVP Objective
> The MVP exists to prove that an Australian mortgage broker will hand off borrower document collection and verification to the AI agent, and act on its "ready for submission" or "exception" signal without redoing the check manually.

### MVP Hypothesis
A broker will trust and use an AI-driven document checklist → collection → verification → cross-validation pipeline for real borrowers if it is reliably accurate and clearly explains any exception.

### MVP User Journey
Broker assigns a borrower → AI sends checklist → borrower uploads documents via chat → AI extracts, verifies, cross-validates → AI either says "ready" or flags specific missing/conflicting items and re-requests from the borrower → broker gets one final notification to review and submit.

### MVP Success Definition
A real borrower's document set is fully collected, verified, and cross-validated by the AI end-to-end, with the broker only intervening on flagged exceptions — not re-checking clean files.

---

## 8. MVP Scope

| Priority | Features |
|---|---|
| **MUST HAVE** | Broker assigns borrower; automated checklist messaging; document upload & tracking; OCR + structured extraction; per-document verification; cross-document validation; automated follow-up for missing/bad documents; broker notification on ready/exception; full audit log of every step |
| **SHOULD HAVE** | Broker dashboard/status view beyond chat notifications; WhatsApp as a channel (Telegram is the current live channel) |
| **COULD HAVE** | Multi-lender document-requirement variants; analytics on bottlenecks/SLA; voice-based borrower interaction |
| **WON'T HAVE (MVP)** | Lending decisions, application auto-population into lender systems, direct lender submission, CRM integrations |

The MVP is strictly: **post-sales-meeting borrower document collection → processing → broker review.** It is not a full loan-processing or CRM platform.

---

## 9. Core MVP Features

### Feature: Automated Document Checklist & Collection
**Purpose:** Remove manual checklist-sending and document chasing from the broker.
**How it works:** Broker assigns borrower → Conversation Manager sends checklist → borrower uploads via chat → Document Intake logs and tracks against checklist → Reminder Agent follows up automatically on missing items.
**Acceptance Criteria:**
- Checklist sent within minutes of broker assignment.
- Every uploaded document logged against the correct checklist item.
- Automated reminder fires on a defined cadence for missing items, no manual trigger.
- Broker can see collection status without asking the borrower.

### Feature: Document Verification
**Purpose:** Catch bad or invalid individual documents automatically.
**How it works:** OCR extracts text → Document Intelligence structures fields → Verification checks required-field completeness and expiry validity.
**Acceptance Criteria:**
- Every document checked for name, DOB, address, expiry as applicable.
- Expired documents flagged automatically, not passed silently.
- Verification result stored and auditable.

### Feature: Cross-Validation
**Purpose:** Catch inconsistencies between documents that a single-document check would miss.
**How it works:** Cross-Validation Agent compares name/address/DOB/ID details across all of a borrower's submitted documents.
**Acceptance Criteria:**
- Mismatches between any two documents are flagged with the specific conflicting fields.
- A fully consistent document set is marked clean.
- No mismatch is ever silently dropped or auto-resolved.

### Feature: Decision Gate & Broker Handoff
**Purpose:** Give the broker one clear, trustworthy signal instead of raw data to sift through.
**How it works:** Decision Agent reads verification + cross-validation results → outputs APPROVED / MORE_DOCUMENTS_REQUIRED / MANUAL_REVIEW → Broker Notification sends the outcome.
**Acceptance Criteria:**
- Decision always traceable to the underlying verification/cross-validation records.
- Broker never has to re-derive why a decision was made — reason is included.
- MANUAL_REVIEW always routes to a human, never auto-resolved by AI.

---

## 10. Borrower & Broker Experience

### Borrower Experience
```
Receive Message
↓
See Checklist
↓
Upload Documents
↓
Receive Confirmation
↓
Respond to Missing/Conflicting Document Requests
↓
Complete Collection
```

**Example conversation:**
> AI: "Hi [Name], your broker has started your home loan application. To move forward, please send: 1) Photo ID, 2) Last 2 payslips, 3) 3 months bank statements."
> Borrower: *[uploads ID photo]*
> AI: "Thanks. We've received your ID and it's now being processed."

### Broker Experience
```
Assign Borrower to AI
↓
Monitor Progress (passive — no action needed unless flagged)
↓
Review Exceptions (only when raised)
↓
Receive "Ready for Submission" Notification
↓
Application Ready
```

---

## 11. AI Boundaries & Human Escalation

### AI CAN
- Communicate with the borrower
- Request and track documents
- Classify and extract document data
- Perform defined verification and cross-validation checks
- Identify missing or inconsistent information
- Follow up automatically
- Escalate exceptions to the broker

### AI CANNOT
- Make lending decisions
- Approve or reject loans
- Invent or assume information not present in a document
- Claim a document is verified without evidence
- Provide financial or legal advice
- Override a broker decision

### Human Escalation Triggers
- Low confidence in extraction or matching
- Documents conflict and cannot be resolved by rule
- Required information cannot be verified
- Borrower requests a human
- Borrower disputes a verification result
- Repeated follow-up failures

---

## 12. Technical Overview

- **Frontend:** Broker-facing notifications today (chat-based); dashboard is a SHOULD-HAVE, not yet built.
- **Backend / Orchestration:** n8n, running a metadata-driven workflow engine — behavior lives in database tables (workflow definitions, stages, steps, instances), not hardcoded in workflows.
- **AI/LLM layer:** Per-agent system prompts (Conversation Manager, Verification, Cross-Validation, Decision) with strict scope boundaries per agent.
- **Database:** Postgres/Supabase — brokers, borrowers, loan_applications, document_checklists, document_types, workflow engine tables, full execution/event audit trail.
- **Document storage & OCR/Intelligence:** Dedicated intake, OCR, and structured-extraction stages, each independently auditable.
- **Communication channel:** Telegram is live today; WhatsApp is planned but not yet implemented (current gap, see Risks).
- **Logging/Audit:** Every agent execution and workflow event is logged — this is a compliance and debugging requirement, not optional.

*(Full schema, node-level n8n design, and prompts exist as separate technical documents — not included here by design.)*

---

## 13. Success Metrics

### Primary / North Star Metric
**Median time from sales meeting completion to broker-review-ready application.**

### Supporting Metrics
- Document completion rate (borrower fully submits checklist)
- AI automation/containment rate (% of files needing zero manual broker chasing)
- Human escalation rate (% of files requiring manual review)
- Verification/cross-validation accuracy (flagged issues confirmed real, not false positives)
- Extraction accuracy (OCR/Document Intelligence correctness)
- Broker time saved per file (self-reported / observed)

Each metric ties directly back to proving the MVP hypothesis: less broker time, same or better document accuracy.

---

## 14. Risks, Assumptions & Open Questions

| Type | Item | Importance | How to Validate |
|---|---|---|---|
| Risk | WhatsApp not yet implemented; Telegram is the only live channel | High | Confirm with target brokers whether Telegram is acceptable for pilot, or WhatsApp is a hard requirement before pilot |
| Risk | Broker human-checkpoint (review/submission gate) routing not yet built in the orchestrator | High | Must be built before any real pilot — file cannot silently stall at broker review |
| Risk | AI accuracy on document extraction/cross-validation not yet stress-tested on messy real-world documents | High | Run pilot on a real but small batch of borrower files before wider rollout |
| Assumption | Brokers will trust an AI "ready for submission" signal without independently re-checking | High | Pilot with 1–2 friendly brokers, measure whether they re-check anyway |
| Assumption | Borrowers will engage with a chat-based AI for document upload as readily as with a human | Medium | Pilot borrower engagement/completion rate |
| Risk | Privacy/security of ID and financial documents in transit and storage | High | Requires explicit data handling and compliance review before any real borrower data is processed |
| Risk | Regulatory/compliance requirements for AI-assisted loan processing in Australia | High | Requires legal/compliance verification — not assumed in this document |
| Risk | Scope creep toward a full CRM/lender-submission platform | Medium | Enforce MVP scope boundary in Section 8 |

---

## 15. Roadmap & Mentor Decisions

### Phase 1 — Validation (mostly done)
Architecture, database schema, workflow contracts, and individual agent workflows (WF-001 through WF-010) have been designed and largely built and unit-tested with real data.

### Phase 2 — MVP (in progress)
Close remaining wiring gaps: broker human-checkpoint routing, final live-wiring of Reminder Agent triggers from Verification/Cross-Validation, and decide on Telegram-only vs. WhatsApp for pilot channel.

### Phase 3 — Pilot
Run with 1–2 real brokers and real (consented) borrower files. Measure the primary metric and escalation rate. Do not scale until pilot accuracy and broker trust are confirmed.

### Future / V2
WhatsApp channel, broker dashboard, voice AI, CRM integrations, lender-specific document intelligence, automated application population, direct lender submission, advanced analytics. **None of these are MVP — keep them out until Phase 3 validates the core loop.**

---

## Mentor Review

### Founder Decisions Required
1. Is Telegram-only acceptable for pilot, or is WhatsApp a hard requirement before any broker will use this?
2. Which 1–2 brokers will run the pilot, and on how many real files?
3. What is the compliance/privacy review process before real borrower ID/financial documents flow through the system?
4. Is a broker dashboard needed for pilot, or are chat notifications sufficient?
5. What is the acceptable false-positive/false-negative rate for cross-validation before brokers stop trusting the "ready" signal?

### Questions for Mentors
1. How should a fintech-adjacent AI tool position itself regarding AFCA/ASIC-type compliance expectations in Australia?
2. What's a realistic minimum pilot size to generate a credible trust signal from brokers?
3. Is there a standard document-verification accuracy bar in this industry to benchmark against?
4. How defensible is this against a broker simply using ChatGPT + a checklist template manually?
5. Should broker dashboard be pulled into MVP, or is chat-only defensible for pilot?
6. What's the right way to price this — per file, per broker seat, or per borrower?
7. How much of the "trust the AI" risk is solved by transparency (showing evidence) vs. just accuracy?

### Product Champion's Assessment
1. **Strongest part:** The cross-validation step — this is the actual differentiator over "just an AI chatbot," because it's the error class brokers currently catch manually and inconsistently.
2. **Biggest weakness:** No broker dashboard yet — the entire broker-side experience currently depends on chat notifications, which may not feel "real" enough for a paying broker.
3. **Biggest MVP risk:** Broker human-checkpoint routing isn't built yet — without it, a file can stall silently at review, which would kill trust in a pilot instantly.
4. **Most important assumption:** Brokers will act on the AI's "ready" signal without redoing the check themselves. If this is false, there is no time savings and no product.
5. **Feature most likely to cause scope creep:** A broker dashboard growing into a full CRM.
6. **What should be removed from MVP:** Nothing currently in the MUST-HAVE list — it's already tight. WhatsApp and dashboard are correctly parked as SHOULD-HAVE.
7. **Recommended next step:** Close the broker-checkpoint routing gap and the two remaining live-wiring stubs, then run the smallest possible real pilot (1 broker, 2–3 real files) before building anything else.
