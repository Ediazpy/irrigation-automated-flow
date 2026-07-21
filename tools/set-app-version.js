/**
 * Update metadata/app_version after a hosting deploy.
 *
 * Clients read this document to show the "update available" prompt; the
 * security rules make metadata read-only for clients, so the version is
 * written here with the Admin SDK.
 *
 * Usage:
 *   set GOOGLE_APPLICATION_CREDENTIALS=path\to\serviceAccountKey.json
 *   node tools/set-app-version.js 2.1.0
 */
const admin = require('firebase-admin');

const version = process.argv[2];
if (!version) {
  console.error('Usage: node tools/set-app-version.js <version>');
  process.exit(1);
}

admin.initializeApp();
admin.firestore().collection('metadata').doc('app_version').set({
  version,
  updated_at: new Date().toISOString(),
}).then(() => {
  console.log(`metadata/app_version set to ${version}`);
  process.exit(0);
}).catch((e) => {
  console.error(e);
  process.exit(1);
});
