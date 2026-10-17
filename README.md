# Nexora Finance Manager

A browser-based starter app for importing bank statements, categorising transactions with IF/THEN rules, maintaining transaction notes, and exporting a CSV.

## Current features
- Import CSV and Excel (.xls/.xlsx) statements.
- Best-effort text extraction from digitally generated PDFs using PDF.js. Scanned PDFs and bank-specific layouts may not parse correctly.
- Categorise transactions with starter narration patterns or user-created rules.
- Rule conditions: amount threshold, narration contains, or debit/credit type; optional extra narration condition.
- Review/edit category, ledger/account and transaction notes.
- Basic inflow/outflow dashboard, category breakdown, duplicate skipping and CSV export.
- Browser localStorage persistence on the same browser/device.

## Run
Open `index.html` in a modern browser with an internet connection (third-party libraries load from CDNs), or enable GitHub Pages to publish it.

## Important limitations
- This is a prototype, not a production accounting system. Always verify extracted rows and rule assignments.
- No live bank connection, Account Aggregator integration, Firebase cloud sync, user login, or multi-device sync is implemented yet.
- Data currently stays in this browser's localStorage. Clearing browser data can erase it. Export CSV backups regularly.
- Do not upload real customer financial statements to a public website. If deploying for real use, make the repository and hosting access appropriate, implement authentication and strict per-user access rules, secure backend secrets, and review privacy/compliance requirements.
- Never provide a bank password, UPI PIN, or OTP to this app.
