# Correction: WF-009's "duplicate telegram_chat_id" flag was a misdiagnosis

`WF009_status.md` (Aug 27) logged a known gap: "two different `borrowers`
rows... appear to share the same `telegram_chat_id`." Investigated today
(Aug 30) as part of closing out the open-items list — **this was incorrect.**

Only two borrower records exist in the system:
- `ce2f172a-...` "John Smith", `telegram_chat_id: NULL`
- `22b42868-...` "Test Borrower", `telegram_chat_id: 6569431491`

`GROUP BY telegram_chat_id HAVING COUNT(*) > 1` returns zero rows. The
unique index (`idx_borrowers_telegram_chat_id`) has held throughout. There
is no duplication.

**What actually happened:** the borrower record's placeholder name field
says "Test"/"Borrower" (same test-data naming convention as "Test Broker",
"APP-TEST-0001" used throughout this project), while the real human
operating that Telegram account is Bhargav Gavini. That's a naming
convention, not a second borrower row. Whoever wrote or read that note
conflated "the name field says Test" with "there must be a separate real
borrower record" — there isn't one.

No action taken, no data changed. Flagging this correction so the
misdiagnosis doesn't get treated as a real finding in a future session or
repeated.
