# Nexora Finance Manager — Privacy Policy

**Effective date:** 18 October 2026

This policy explains how Nexora Finance Manager ("Nexora", "we") handles information when you use the app. The app provides personal finance tracking, manual transaction entry, bank-statement import and optional bank SMS tracking.

## Information processed

- **Account information:** email address and account identifier used by Firebase Authentication.
- **Financial transactions:** transaction title, amount, date, income/expense classification, category, ledger, notes and source that you enter or import.
- **Optional SMS tracking:** only after you choose to enable it and grant Android SMS permissions, Nexora reads SMS messages on your device to look for bank transaction notifications. Message text is processed on-device by the app's current parser. When a message is recognised, the app saves derived transaction fields to your user-scoped Firestore collection, including amount, date, title/category and the SMS sender address in the transaction note. The app is not designed to upload the full SMS body. Detection can be incomplete or incorrect, so review transactions.
- **Statement files:** a file you select for import is processed by the app to extract transaction rows. Review the preview before relying on imported results.

## Why information is used

Information is used to sign you in, show and synchronise your finance records, import statements, detect possible bank transactions from SMS when enabled, and prevent duplicate SMS-derived entries. Nexora does not ask for bank passwords, UPI PINs or OTPs.

## Storage and service providers

Account and transaction records are stored using Google Firebase Authentication and Cloud Firestore. These services process data under Google's applicable terms and privacy practices. Access to transaction records is scoped by the app to the signed-in user's account, but no online service can be guaranteed completely risk-free.

## Your choices and permissions

SMS tracking is optional. You can decline the disclosure or deny Android SMS permissions; SMS-based detection will then not run. You can use manual entry and supported statement imports instead. Android settings can be used to revoke SMS permissions. Revoking permission stops future inbox access but does not automatically delete transactions already saved to your account.

## Retention and deletion

Records remain in your account until they are deleted through available app features or a deletion request is processed. For help with account or data deletion, contact the developer at **rohit.fcg123@gmail.com**. Include the account email in the request, but never send passwords, bank credentials, PINs or OTPs.

## Children and sharing

Nexora is intended for personal finance management, not for children. We do not sell personal financial information. Do not use the app to process another person's messages or financial records without lawful authority and their permission.

## Security and accuracy

Use a strong account password and keep your device secure. SMS parsing is rule-based and may misread a transaction or miss a bank format. Always verify entries against your bank records. This app is not a bank and does not provide a live Account Aggregator connection.

## Changes and contact

This policy may be updated when the app's data practices change. The effective date above will be revised. Questions or data-deletion requests: **rohit.fcg123@gmail.com**.
