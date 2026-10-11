# WhatsApp API + Meta Ads MCP — Handoff Note

**Date:** 2026-09-20 (last updated 2026-09-21)
**Purpose:** Continue two workstreams in the next chat without re-doing work or repeating dead ends:
1. Get the WhatsApp Cloud API number live (for the n8n AI agent to auto-converse with leads/borrowers)
2. Set up Meta Marketing API access so Claude Code can build/optimize ad campaigns

---

## Current status (as of Sep 21, 2026)

**Priority 2 (Marketing API access) is now DONE end-to-end.** New User Access Token generated for the "AUBrokerFlow Comms" app with 4 permissions (`whatsapp_business_management`, `whatsapp_business_messaging`, `ads_management`, `ads_read`), and a live test call `GET /act_120249934885860335/campaigns` returned a valid `{"data": []}` response — proving real Marketing API access to the Ad Account. See "Meta Ads Account" section below for IDs. Next step is deciding how campaigns get created going forward (n8n HTTP workflow vs. direct Graph API calls from Claude Code) — not yet built.

**WhatsApp number is STILL NOT live.** Root cause chain, fully diagnosed this session:
1. Business Verification for "AU Broker Flow" Business Portfolio (ID `1627184102289373`) is confirmed **Verified** (Security Center, checked live Sep 21).
2. Phone number ownership/OTP is confirmed already verified (`/request_code` returns `error_subcode 2388366` "Phone number already verified" — do not retry this call).
3. Despite both of the above, `POST /1354947867693478/register` still fails with `"Unverified WABA"` (code 100, OAuthException).
4. **Root cause found:** WABA `965735519121907` has its own independent "**Account status: Review in Progress**" flag in WhatsApp Manager (Settings → WhatsApp accounts → this WABA), separate from Business Verification. This is what's actually blocking `/register`. It is not exposed clearly in the API error text.

**Action taken:** attempted to file a Meta Direct Support ticket to escalate the stuck WABA review. **This is a dead end** — see below. User explicitly redirected focus to Priority 2 (now done) while this stays blocked.

---

## Meta Ads Account (NEW — set up this session)

| Item | Value |
|---|---|
| Ad Account name | AU Broker Flow Ads |
| Ad Account ID | `act_120249934885860335` (numeric: `120249934885860335`) |
| Ad Account timezone | Asia/Kolkata (IST) |
| Ad Account currency | INR |
| Business Portfolio | AU Broker Flow (`1627184102289373`) — same as WhatsApp setup |
| Payment method | **NOT YET ADDED** — Claude cannot enter card/billing details (safety restriction). User must add this manually in Business Manager → Ad Accounts → Billing before any campaign can actually spend money. |
| Marketing API use case | Added to "AUBrokerFlow Comms" app via App Dashboard → Use Cases → "Create & manage ads with Marketing API" (was missing initially, which is why `ads_management`/`ads_read` didn't appear in Graph API Explorer's permission picker until this was added). |
| Access token scopes confirmed working | `whatsapp_business_management`, `whatsapp_business_messaging`, `ads_management`, `ads_read` — all 4 granted via real OAuth consent flow (see technique below), verified live against `/act_120249934885860335/campaigns`. |

**Still to decide:** whether campaign creation/management happens via an n8n HTTP Request workflow calling the Marketing API, or via direct Graph API calls scripted elsewhere. Not yet built either way.

---

## Technique: fixing "Generate Access Token" when it silently does nothing in Graph API Explorer (browser automation)

If clicking "Generate Access Token" in Graph API Explorer appears to do nothing (no popup, no new tab, token unchanged), it's because **Chrome's popup blocker silently blocks the `window.open()` call** the button triggers — this happens specifically when the click is dispatched via automation (not a "trusted" user gesture in the browser's eyes). Confirmed via `window.open('about:blank')` test returning a blocked/closed window handle.

**Fix that worked:** use `javascript_tool` to monkey-patch `window.open` right before clicking the button, capture the URL it *would have* opened, then navigate the *current tab* to that URL directly (`window.location.href = capturedUrl`) instead of relying on a popup. This lands on Meta's real OAuth consent flow (`www.facebook.com/.../dialog/oauth?...`) in the same tab. Walk through: "Continue as [name]" → asset-selection screen (e.g. which WhatsApp accounts) → final permission review/Save screen → confirmation screen ("X has been connected to [App]") → "Got it" redirects back to the Explorer with the new token auto-populated. Use `find`/ref-based clicks throughout, not fixed coordinates — this flow's button positions shift between screenshots.

This is a reusable workaround any time an OAuth "Generate Token" / "Connect" style button seems inert under Claude in Chrome automation.

---

## What NOT to retry (dead ends confirmed, don't repeat)

1. **Meta System User "permanent token" generation** — fails with "No permissions available" pre-verification. (Still may work now that Business Verification is confirmed Verified, but hasn't been re-tested — low priority since WABA review status is the real blocker now.)
2. **Twilio-managed WhatsApp Sender as a verification bypass** — hits the same Meta Business Verification requirement. Not a shortcut.
3. **Using a third party's registered business identity to pass Business Verification** — explicitly declined (fraud/liability risk). Don't suggest again.
4. **GST-based Udyam registration** — solved via sole-proprietor Udyam path already. Don't redo.
5. **Manually relaying long access tokens through chat by reading screenshots** — causes transcription errors. Have the user copy-paste tokens directly.
6. **WhatsApp Business App (regular phone app)** — no API/webhooks, can't run the n8n AI agent. Manual stopgap only for Click-to-WhatsApp ads.
7. **Retrying `/request_code`** — phone ownership is already verified; retrying just returns the same "already verified" error. Do not call this again.
8. **Retrying `/register` as-is** — will keep failing with "Unverified WABA" until the WABA's "Review in Progress" status clears. No point retrying until that changes.
9. **Meta Direct Support ticket via `business.facebook.com/direct-support/`, topic "Dev: Account & WABA," Request Type "Account Activity Issues":** the case-info form's **Phone Number field is a combobox that never populates a dropdown for this number**, no matter the format tried (`+61495100317`, `+6149510031`, `495100317`, `495`, `+61 495 100 317`). Confirmed via network inspection that typing in this field triggers **zero API calls** — it's a static client-side list of the account's already-*registered* numbers, and since this number never completed registration it will never appear. This field cannot be made to validate. **Don't spend more time on this exact path.**
10. **Meta Direct Support ticket via topic "Dev: Cloud API," Request Type "Phone number Registration API":** this form has no phone-number combobox (just Title/Description/Request Type), so it was fully filled in correctly (title, full description with WABA ID, phone number, error text, fbtrace_id) and submitted — **but Submit fails every time with a generic "Something went wrong. An error occurred while creating your question. Please try again later."** Tried 3x, including once with a simplified description (removed raw JSON/curly braces in case that was tripping a backend parser) — same error every time. This looks like a genuine bug/outage on Meta's ticket-creation backend for this topic, not a form-validation issue. **Don't keep retrying this from Claude in Chrome** — it's reproducible and not something automation can work around.

---

## Key IDs and identifiers (don't re-look these up)

| Item | Value |
|---|---|
| Meta App name | AUBrokerFlow Comms |
| Meta App ID | `1745711816546211` |
| WhatsApp Business Account (WABA) name | AU Broker Flow |
| WABA ID | `965735519121907` |
| WABA Account status (Sep 21) | **Review in Progress** — this is the live blocker |
| Phone number | +61 495 100 317 |
| Phone Number ID | `1354947867693478` |
| Phone number status | Pending |
| Business Portfolio name | AU Broker Flow |
| Business Portfolio ID | `1627184102289373` |
| Business Verification status (Sep 21) | Verified |
| Business address (matches Udyam cert) | 26-20-9, HPCL Lane, Chaitanya Nagar, Chinna Gantyada, Gajuwaka, Visakhapatnam, Andhra Pradesh 530026, India |
| Business phone (Meta Business Info) | +91 9640414169 |
| Business website | https://www.aubrokerflow.com |
| Udyam Registration Number | UDYAM-AP-10-0148030 |
| Ad Account ID (NEW) | `act_120249934885860335` |
| n8n instance | https://n8n-gwvc.srv1766177.hstgr.cloud |
| n8n workflow (Conversation Manager) | WF001, workflowId `oAiQoPYm2BFbPyc9` |
| n8n WhatsApp Trigger credential | "WhatsApp OAuth (AU Broker Flow)" — id `aWywywUI5m2oEVkI` (type `whatsAppTriggerApi`) |
| n8n WhatsApp Send credential | "WhatsApp API (AU Broker Flow)" — id `htpTnQEAwm44UaiN` (type `whatsAppApi`) |
| Supabase project | `ucoedigbgtbklkqqjqpw` (confirmed **INACTIVE/paused** this session — needs explicit user approval to restore) |
| Pending Supabase migration | `056_add_whatsapp_fields_to_borrowers.sql` (not yet applied) |

n8n WF001 already has a standalone WhatsApp Trigger → WhatsApp Send Test Reply branch added and published, wired to the credentials above, but **not yet merged** into the real borrower-resolution/AI-agent conversation logic (Telegram branch). That merge is still pending.

**Security issue found this session, not yet fixed:** the "Upload to Supabase Storage" HTTP Request node inside WF001 has a **hardcoded Supabase `service_role` JWT** in its headers (`apikey` and `Authorization`). This should move to an n8n credential instead of sitting in plaintext in the workflow JSON. Needs user go-ahead to fix.

---

## Priorities for next chat, in order

### Priority 0 — Unblock the WABA "Review in Progress" status
The Direct Support ticket route is a dead end (see #9/#10 above). Options not yet tried:
- Retry the "Dev: Cloud API" ticket submission again later (Meta's backend error could be transient/an outage rather than permanent — worth one retry in a few hours, but don't loop on it repeatedly in one session).
- Try filing via a completely different entry point: the developer-facing support form at `developers.facebook.com/support/` (not yet attempted) rather than `business.facebook.com/direct-support/`.
- Check the Meta for Developers community forum / WhatsApp Business Platform support Slack-equivalent channels for others reporting the same "Account status stuck at Review in Progress" issue.
- Just wait and re-check WABA Account status periodically (Meta reviews sometimes clear on their own after some days) — re-check via WhatsApp Manager → Settings → WhatsApp accounts → this WABA, not via the API error message (which doesn't clearly surface this specific status).

### Priority 1 — Meta ads → WhatsApp lead capture
Goal: run Meta ads that route prospects into a WhatsApp chat, qualify them, book a demo.
- **Immediate/no-blocker path:** Click-to-WhatsApp ads pointing at the regular WhatsApp Business App number — works today, no verification needed, but qualification is manual (no AI automation possible on this number).
- **Automated path (blocked until WABA review clears):** once WABA review clears and `+61 495 100 317` is registered, flip ads to that number and let the n8n AI agent (WF001) handle qualification + demo booking automatically.
- **Blocked on billing:** ad account exists (`act_120249934885860335`) but has no payment method yet — user must add this before any campaign can go live.
- **Not yet started:** actually building/launching the Meta ad campaign itself (targeting, creative, budget).

### Priority 2 — Meta Marketing API access for Claude Code to manage campaigns — DONE (token + verified API call)
- ✅ Ad Account created (`act_120249934885860335`).
- ✅ Marketing API use case added to the app.
- ✅ Access token generated with `ads_management` + `ads_read` (plus existing WhatsApp scopes).
- ✅ Verified live: `GET /act_120249934885860335/campaigns` → `{"data": []}`.
- ⬜ Add payment method to ad account (user must do this manually).
- ⬜ Decide + build the actual campaign-management mechanism (n8n HTTP workflow vs. scripted Graph API calls).
- ⬜ Extend token to long-lived (60-day) if needed for production use — current token is short-lived, fine for testing only.

### Priority 3 — Once WABA review clears / number registers
- Retry `/register` on Phone Number ID `1354947867693478` with PIN `311990` (already set, confirmed working format).
- Merge the standalone WhatsApp Trigger/Send branch in WF001 into the real borrower-resolution/AI-agent conversation logic.
- Fix the hardcoded Supabase service_role JWT in WF001's "Upload to Supabase Storage" node (move to n8n credential).
- Restore/unpause Supabase project `ucoedigbgtbklkqqjqpw` and apply pending migration `056_add_whatsapp_fields_to_borrowers.sql` (needs user approval).
- End-to-end test: real WhatsApp send/receive through the n8n agent.

---

## Notes on working style from this session
- User wants speed and decisiveness — auto mode, minimal clarifying questions, act and report.
- User is in India (freelancer), client-facing product is for Australian mortgage brokers — don't confuse the two Meta Business setups (this AU Broker Flow account is the user's own lead-gen/marketing business, separate from any future client-specific WABA setups for actual AU mortgage broker clients under Priority 2 of the original project instructions).
- Any government form fields (Udyam, etc.) or anything resembling a real-world transaction/payment/credential entry — Claude cannot fill these directly due to safety restrictions. The user has to type those themselves. This includes adding a payment method to the new Ad Account.
- CAPTCHAs must be solved by the user — Claude cannot complete them.
- When a UI element (dropdown/combobox) needs an exact click target, use `read_page`/`find` to get an element `ref` and click by ref, not by pixel coordinate — Meta's UIs (Business Manager, Graph API Explorer) are flaky with coordinate-based clicks (layout/viewport shifts between screenshots, especially after the page auto-scrolls).
- If a `type` action throws a CDP timeout error but the field visibly has the right text in the next screenshot, treat it as a benign/cosmetic tool error — don't retype and risk duplicating text.
- Committing an autocomplete suggestion (e.g. adding a permission in Graph API Explorer) is more reliable via keyboard (`ArrowDown` then `Return`) than via mouse click on the suggestion — mouse clicks on these dropdowns frequently miss due to layout shifts.
- See the "Generate Access Token" popup-blocker workaround above — applies broadly to any OAuth-style button that seems to do nothing under automation.
