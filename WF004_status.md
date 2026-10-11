# WF-004 OCR Agent — Status

**Status: CLOSED. PDF path verified via DB query on Published version (ID#550).**

## Verified Working
GPT-4.1 Vision OCR now handles BOTH direct image uploads AND PDF uploads (via
ConvertAPI pre-conversion). Confirmed via real Telegram-triggered execution,
DB-verified — not just the n8n green checkmark.

- `ocr_results`: `ocr_status = COMPLETED`, `raw_text` populated with real
  transcribed content (Indian driving licence — name, DL number, address,
  issuer, issue date all captured correctly), `processing_time_ms = 5889`.
- `documents.processing_status = OCR_COMPLETED` (confirmed via
  `Set Document OCR_COMPLETED` branch firing → `Respond Success`, not
  `Respond Failed`).
- Test document: `document_id c83e0dc9-e6f2-4fba-a6e3-02839c409396`,
  `ocr_result_id ff1adf58-65e9-4b8f-b226-6fc559146564`, file
  `Bhargav License.pdf` (real ID document, not a placeholder photo — this is
  the first real ID doc to clear the pipeline end to end).

## Bugs Found & Fixed This Session (PDF Path)

### 1. `If` node (mime_type == application/pdf) — phantom placeholder value
The right-hand comparison value looked like it said `application/pdf` but
was actually unset gray placeholder text, not a real entered value — so
`"application/pdf" == ""` evaluated false every time, and PDFs always fell
to the non-conversion branch regardless of actual mime type. Fixed by
retyping the value directly into the field (confirmed solid black text after
click-away) and switching the operator to `contains` / `pdf` for a more
robust substring match, with "Convert types where required" enabled.
**Same phantom-placeholder pattern as bug #3 in the known list — looks
identical to a real value at a glance, must click in and verify.**

### 2. `The Convert API Call` — Form-Data field sent as text, not binary
The Body field (`Name: File`, `Value: data`) had **Type** set to `Form
Data`, which sends the literal string "data" as a text field — not the
actual PDF bytes. ConvertAPI correctly rejected this with
`"File id is not valid."`. Fixed by setting the field's Type to
`n8n Binary File` with `Input Data Field Name: data`, matching
`Download Document`'s binary output key.

### 3. `Encode Base64` — assumed binary output, but ConvertAPI returns JSON
Even after fix #2, `Encode Base64`'s code called
`this.helpers.getBinaryDataBuffer(0, 'data')` unconditionally. ConvertAPI's
actual response is a **JSON body** with the converted image's base64 nested
at `Files[0].FileData` (confirmed via direct inspection of `Merge`'s and
`The Convert API Call`'s OUTPUT — no binary property present on that item at
all, base64 text sitting in JSON instead). `getBinaryDataBuffer` threw a
generic "Unknown error" because there was no binary data to read. Fixed by
branching the code itself:
```js
const mergedItem = items[0].json;
let base64, mime_type;

if (mergedItem.Files && mergedItem.Files[0] && mergedItem.Files[0].FileData) {
  // PDF path — converted via ConvertAPI, base64 already in JSON
  base64 = mergedItem.Files[0].FileData;
  mime_type = 'image/' + mergedItem.Files[0].FileExt;
} else {
  // Direct image upload — real n8n binary data
  const buffer = await this.helpers.getBinaryDataBuffer(0, 'data');
  base64 = buffer.toString('base64');
  mime_type = $('Normalize Input').item.json.mime_type;
}

return [{ json: {
  document_id: $('Normalize Input').item.json.document_id,
  storage_path: $('Normalize Input').item.json.storage_path,
  mime_type,
  ocr_result_id: $('Create OCR Result (PROCESSING)').item.json.id,
  data_uri: `data:${mime_type};base64,${base64}`,
  started_at: Date.now()
} }];
```
This single node now handles both branches (PDF-converted and direct-image)
without a second OpenAI call path or extra HTTP node — kept the
"one OCR code path" architecture decision intact.

## Bug Pattern Confirmed (New Addition to Known List)
**External API response shape must be verified, not assumed, before wiring
downstream nodes.** ConvertAPI's docs/curl examples suggested a file
response; the actual behavior returned JSON with embedded base64. Always
inspect the real OUTPUT (JSON + Binary tabs) of an external HTTP node inside
a real execution before writing code that consumes it — this cost several
retries here, same lesson as the "generic Bad Request" pattern (#5 in prior
known list) but on the output side instead of the error side.

## Known, Deliberate Gap — Not a Bug
`STUB Trigger Document Intelligence` remains a placeholder — not yet wired
to a real `Execute Workflow` call to WF-005. Do not wire live until WF-005's
COMPLETED branch is independently confirmed clean (next session).

## Process Notes
- Manual "Execute step" node tests were unreliable throughout this session
  (showed "No output data" / "Unknown error" against config that later
  proved correct) — every real diagnosis in this session came from
  inspecting a genuine Telegram-triggered execution, never a standalone
  node test. Reconfirms the project's existing testing discipline.
- Save-AND-Publish discipline held throughout — several early confused runs
  traced back to testing against an unpublished "Publish" state rather than
  "Published".

## Next Up
WF-005 Document Intelligence — COMPLETED branch still untested (per
WF005_status.md). Now unblocked: use today's real OCR result
(`ocr_result_id ff1adf58-65e9-4b8f-b226-6fc559146564`,
`document_id c83e0dc9-e6f2-4fba-a6e3-02839c409396`) as the real ID-document
test input. Run WF-005 against it, confirm `extracted_fields` populated with
real values (name, DOB, address, doc number, expiry), `intelligence_status =
'COMPLETED'`, both `Insert Intelligence Result (COMPLETED)` and
`Log Agent Execution (Success)` DB-clean. Audit for `$json`-staleness first
(7th+ confirmed occurrence pattern project-wide) before testing, not after.
