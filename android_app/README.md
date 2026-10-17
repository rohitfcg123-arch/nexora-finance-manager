# Nexora Finance Manager — Flutter Android app

Native Flutter app source. The existing website is unchanged.

## Features in source
- Firebase email/password registration, sign-in and password reset.
- Firestore user-scoped cloud transaction sync.
- Manual income/expense add, edit, delete, date, category, ledger and note.
- CSV, XLS/XLSX import with preview; best-effort text PDF extraction with preview.
- Automatic starter categories, dashboard, transaction list, reports and settings.
- Premium emerald/white theme.

## Setup before production
1. Register Android app package `com.nexora.finance_manager` in Firebase Console.
2. Run FlutterFire CLI in this folder: `flutterfire configure --project=nexora-finance-manager`, then replace `lib/firebase_options.dart` with the generated configuration.
3. Confirm Email/Password provider is enabled and publish the root Firestore rules.
4. Run `flutter pub get`, `flutter analyze`, and test with two separate user accounts.

The current Firebase options are based on the supplied web config as a development bridge; they are not a substitute for registering the Android app and generating native options.

## Import limitations
CSV/XLS/XLSX expects recognizable Date, Narration/Description/Particulars and Debit/Credit or Amount columns. PDF extraction depends on the bank layout and may not parse all statements. Scanned PDFs need OCR. Password-protected PDFs are not decrypted in this version; unlock a copy in a trusted PDF viewer first. Always verify dates, amounts, debit/credit direction, duplicates and categories before using imported data.

SMS tracking is not implemented. Do not upload raw SMS or OTP content to Firebase.
