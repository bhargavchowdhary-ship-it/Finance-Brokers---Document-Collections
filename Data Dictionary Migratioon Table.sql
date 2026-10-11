Relationships

Loan Application
      │
      ├── Application Borrowers
      ├── Document Checklist
      ├── Conversations
      ├── Reminders
      └── Audit Logs

Initial Columns


Column	Description
id	Internal UUID
application_number	Human-readable application reference (e.g., APP-2026-000001)
loan_type	HOME_LOAN, INVESTMENT, REFINANCE, CONSTRUCTION
loan_purpose	PURCHASE, REFINANCE, EQUITY_RELEASE, etc.
requested_amount	Amount requested by the borrower
application_status	Current stage in the workflow
created_at	Creation timestamp
updated_at	Last update timestamp
deleted_at	Soft-delete timestamp


Tables

brokers
borrowers
loan_applications
document_versions
ocr_results

Foreign Keys
Always use:
<parent_table_singular>_id
Examples:
broker_id
borrower_id
application_id
document_id

Indexes

Always use:
idx_<table>_<column>
Examples:
idx_borrowers_broker_id
idx_documents_application_id
idx_messages_conversation_id


