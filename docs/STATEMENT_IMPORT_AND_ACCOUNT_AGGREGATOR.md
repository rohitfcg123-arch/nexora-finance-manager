# Nexora Finance Manager — statement import and bank-sync implementation notes

## Current status (2026-10-18)

This repository contains a Flutter Android app with Firebase email/password authentication and user-scoped Firestore transactions. CSV/XLS/XLSX imports and best-effort text-layer PDF extraction exist. The import flow now generates stable IDs from date + normalized narration + amount + debit/credit direction, checks Firestore in chunks, previews existing duplicates, and imports only new rows.

### Not yet production-ready
- Universal bank-statement parsing is not guaranteed. Each bank, statement version, locale, and export format can vary; the preview is mandatory and users must verify dates, debit/credit, opening/closing balance.
- Scanned/image-only PDFs do not have OCR wired into the Flutter import path yet. Current Syncfusion PDF extraction reads existing text; it does not itself perform OCR. Do not advertise scanned-PDF import as working until an OCR engine and PDF-page rasterization path are integrated and tested on Android.
- Account Aggregator linking and live transaction sync are not implemented. The UI must remain explicit that bank linking is not active.

## Account Aggregator integration — required architecture

India's AA network is consent-driven. Nexora cannot fetch a user's bank transactions merely by adding a button or collecting bank credentials. Before implementing a live connector, choose a provider and confirm that the Nexora business/entity is eligible to act as a Financial Information User (FIU) or can integrate under an eligible regulated partner's arrangement. Confirm the provider's current onboarding, contract, security, and regulatory requirements directly.

Recommended flow:
1. Flutter client asks Nexora backend to create a link/consent session.
2. Backend authenticates the Firebase user and maps the provider session to that UID.
3. Client opens the provider's approved consent/link UI; no bank password, UPI PIN, or OTP is collected by Nexora.
4. Provider sends the user through the consent process and returns a session/status identifier.
5. Backend verifies provider callbacks/webhooks, exchanges or retrieves data using server-side credentials, validates consent scope/expiry, and normalizes transactions.
6. Backend writes only the authenticated user's normalized transactions to Firestore; deduplicates using provider transaction IDs where available.
7. Client displays connection status, last successful sync, consent expiry/revocation, and a manual sync action. Revoke/disconnect must stop future fetches and follow provider retention requirements.

Suggested backend endpoints (illustrative contracts, not live endpoints):
- `POST /v1/bank-links/session` — authenticated Firebase ID token; returns a provider-approved link/consent URL and opaque session ID.
- `GET /v1/bank-links/status` — returns only the signed-in user's connection status.
- `POST /v1/bank-links/sync` — requests a provider-supported sync for an existing valid consent.
- `POST /v1/provider/webhook` — server-to-server callback; verify signatures and replay protection.
- `DELETE /v1/bank-links/{linkId}` — revoke/disconnect as supported by provider.

Security requirements:
- Never place provider API secrets in Flutter, GitHub Pages, or the repository.
- Verify Firebase ID tokens server-side; enforce UID ownership on every endpoint.
- Verify provider webhook signatures, timestamps, and replay protection.
- Encrypt sensitive data in transit and at rest; minimize retention; redact logs.
- Respect consent purpose, data scope, expiry, revocation, and provider terms.
- Add emulator/security tests, audit logs, failure/retry handling, and reconciliation before production.

## OCR implementation gate

For scanned PDFs, integrate an OCR solution that supports Android and a reliable PDF-page-to-image renderer, or a secured server-side OCR pipeline. Decide whether processing must remain on-device or can be sent to a backend. Add page limits, file-size limits, clear permission/privacy disclosures, progress, confidence/uncertain-row review, and tests with scanned statements from several banks. OCR output must go through the same transaction normalization, duplicate detection, preview, and user confirmation as digital PDFs.

## Test checklist before release

- Text PDFs from multiple banks, including wrapped narrations and multi-page statements.
- Scanned PDFs and rotated/low-resolution pages (only after OCR integration).
- CSV/XLS/XLSX with varying column labels, date formats, CR/DR markers, negative values, commas, and blank rows.
- Same statement imported twice: second import adds zero duplicate transactions.
- Same date/merchant/amount but legitimately repeated purchases: users can distinguish/review collisions; prefer provider transaction IDs or bank reference IDs where available.
- Totals and opening/closing balances compared against the original statement.
- AA happy path, denied consent, expired/revoked consent, provider outage, duplicate webhook, unauthorized UID, and user disconnect.
