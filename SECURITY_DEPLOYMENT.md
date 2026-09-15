# IAF Security Hardening — Deployment Runbook

Status (deployed 2026-07-20; app was in testing phase so no data migration was needed):

- ✅ Firebase Auth (email/password) is the only auth system in the app;
  the Email/Password provider is enabled in the console
- ✅ Custom claims carry `role` ('manager' | 'technician') and `companyId`
- ✅ Hardened `firestore.rules` with default-deny — **deployed and verified
  live** (unauthenticated REST reads of clients/users/password_reset_requests
  return 403; public_quotes token gets pass)
- ✅ Firestore indexes deployed
- ✅ New client deployed to https://irrigation-automated-flow.web.app
- ✅ 32 rules tests pass against the local emulator (`test/rules`);
  CI workflow in `.github/workflows/firestore-rules.yml`
- ✅ `.github/workflows/deploy.yml` (GitHub Pages deploy of the old
  local-auth build, now `DEPRECATED_irritrack_mobile/`) disabled — manual trigger only
- ⬜ **Cloud Functions — blocked on the Blaze plan.** Until deployed,
  "Create Account" fails at the claims step and the app has no usable
  accounts. See "Remaining step" below.
- ⏸️ `storage.rules` written but Firebase Storage is not set up on the
  project (no bucket exists, so nothing is exposed). If you enable Storage
  later: `firebase deploy --only storage`.

## Remaining step: Cloud Functions

1. Upgrade the project to Blaze (pay-as-you-go):
   https://console.firebase.google.com/project/irrigation-automated-flow/usage/details
   (Functions on this scale sit comfortably in the free tier — Blaze just
   requires a billing account on file.)
2. Deploy:
   ```bash
   firebase deploy --only functions
   ```
3. Then create the first company via the app's "Create Account" flow and
   verify: sign in, add a technician from Users, and confirm the technician
   can sign in and see company data.

Old email-keyed test data in Firestore is now inaccessible to clients under
the new rules (it lacks `company_id` stamps). Delete it from the console
whenever convenient — nothing reads it.

## Routine deploys from here on

```bash
firebase use                              # must print irrigation-automated-flow
firebase deploy --only firestore:rules    # after any rules change (run npm test first!)
firebase deploy --only firestore:indexes
firebase deploy --only functions
flutter build web --release && firebase deploy --only hosting
node tools/set-app-version.js <version>   # metadata is admin-write only now
```

Note: `tools/migrate-to-firebase-auth.js` (legacy data migration) ended up
unused — the app was still in testing, so the email-keyed test data was
abandoned in place instead of migrated. The script is kept for reference.

## Standing notes

- **Rules tests**: `cd test/rules && npm test` (Node 20 + Java 17 required).
  CI runs them via `.github/workflows/firestore-rules.yml` whenever
  `firestore.rules` or the tests change.
- **Cloud Functions bypass rules by design** — every callable in
  `functions/index.js` verifies `request.auth` and role claims itself. Keep
  it that way for any new function.
- **Secrets**: no service-account key has ever been committed (verified in
  git history). A RevenueCat **test** key (`test_dALH...`) was committed and
  removed in `c93354f`; it is still in history — rotate it in the RevenueCat
  dashboard if that project is still in use. The Firebase web config in
  `lib/firebase_options.dart` is public by design and fine.
- **App Check**: worth enabling (Console → App Check) once the app is stable
  on the new rules — defense in depth, not a substitute for rules.
- `data/irritrack_data.json` is a local Python-prototype data file (untracked,
  gitignored) containing customer PII — consider deleting it from the machine
  when no longer needed. `main.py` is prototype code with a placeholder
  password; it is not part of the shipped app.
