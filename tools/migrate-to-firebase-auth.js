/**
 * One-time migration: local/custom auth  ->  Firebase Auth + tenant model.
 *
 * What it does (in order):
 *  1. Creates a companyId for the existing dataset.
 *  2. Imports every users/{email} doc into Firebase Auth. Legacy passwords
 *     are unsalted SHA-256 hex digests, imported with the SHA256 scheme so
 *     existing passwords keep working. Plaintext legacy passwords are hashed
 *     first. Users can also just use "Forgot Password".
 *  3. Sets custom claims {role, companyId} on every imported user
 *     ('manager' | 'technician', straight from the old user doc).
 *  4. Writes uid-keyed users/{uid} profile docs (no password field) and
 *     deletes the old email-keyed docs.
 *  5. Re-keys business docs from {N} to {companyId}_{N} and stamps
 *     company_id / created_by / created_at on each.
 *  6. Moves settings/company -> settings/{companyId} and
 *     metadata/counters -> counters/{companyId}.
 *  7. Backfills public_quotes/{token} for outstanding sent/viewed quotes so
 *     customer approval links that are already in the wild keep working.
 *  8. Deletes the password_reset_requests collection.
 *
 * Usage:
 *   set GOOGLE_APPLICATION_CREDENTIALS=path\to\serviceAccountKey.json
 *   node tools/migrate-to-firebase-auth.js            (dry run — prints plan)
 *   node tools/migrate-to-firebase-auth.js --apply    (actually migrates)
 *
 * Run this BEFORE deploying the hardened rules. It is idempotent-ish but
 * intended to run once; take a Firestore export first:
 *   gcloud firestore export gs://<bucket>/pre-auth-migration
 */
const admin = require('firebase-admin');

const APPLY = process.argv.includes('--apply');
const BUSINESS_COLLECTIONS = [
  'properties',
  'inspections',
  'quotes',
  'repair_tasks',
  'clients',
  'invoices',
];

admin.initializeApp();
const db = admin.firestore();

function isSha256Hex(s) {
  return typeof s === 'string' && /^[0-9a-f]{64}$/.test(s);
}

async function main() {
  console.log(APPLY ? '=== APPLY MODE ===' : '=== DRY RUN (pass --apply to execute) ===');

  // ---- 1. Company id ----
  const companyId = db.collection('settings').doc().id;
  console.log(`companyId for existing data: ${companyId}`);

  // ---- 2+3+4. Users ----
  const userDocs = await db.collection('users').get();
  const emailKeyed = userDocs.docs.filter((d) => d.id.includes('@'));
  console.log(`users to migrate: ${emailKeyed.length}`);

  let managerUid = null;
  const emailToUid = {};

  if (APPLY) {
    const crypto = require('crypto');
    const importRecords = [];
    for (const doc of emailKeyed) {
      const data = doc.data();
      const email = doc.id.toLowerCase();
      const uid = crypto.randomUUID().replace(/-/g, '');
      emailToUid[email] = uid;
      let passwordHashHex = data.password || '';
      if (passwordHashHex && !isSha256Hex(passwordHashHex)) {
        // Legacy plaintext password — hash it the same way the old app did
        passwordHashHex = crypto.createHash('sha256').update(passwordHashHex).digest('hex');
      }
      const record = {
        uid,
        email,
        displayName: data.name || '',
        disabled: data.is_archived === true,
      };
      if (passwordHashHex) {
        record.passwordHash = Buffer.from(passwordHashHex, 'hex');
        record.passwordSalt = Buffer.from('');
      }
      importRecords.push(record);
    }

    if (importRecords.length > 0) {
      // Firebase SHA256 scheme computes hash(salt + password); with an empty
      // salt and 1 round this equals the app's plain SHA-256(password).
      const result = await admin.auth().importUsers(importRecords, {
        hash: { algorithm: 'SHA256', rounds: 1 },
      });
      console.log(`imported: ${result.successCount}, failed: ${result.failureCount}`);
      result.errors.forEach((e) =>
        console.error(`  import error [${e.index}] ${importRecords[e.index].email}: ${e.error.message}`));
      if (result.failureCount > 0) {
        throw new Error('User import had failures — aborting before data migration.');
      }
    }

    for (const doc of emailKeyed) {
      const data = doc.data();
      const email = doc.id.toLowerCase();
      const uid = emailToUid[email];
      const role = data.role === 'manager' ? 'manager' : 'technician';
      if (role === 'manager' && !managerUid) managerUid = uid;

      await admin.auth().setCustomUserClaims(uid, { role, companyId });
      await db.collection('users').doc(uid).set({
        email,
        name: data.name || '',
        role,
        is_archived: data.is_archived === true,
        company_id: companyId,
        created_by: uid,
        created_at: new Date().toISOString(),
      });
      await db.collection('users').doc(doc.id).delete();
      console.log(`  ${email} -> ${uid} (${role})`);
    }
  } else {
    emailKeyed.forEach((d) => console.log(`  would migrate ${d.id} (${d.data().role})`));
  }

  const createdBy = managerUid || 'migration';

  // ---- 5. Business docs: re-key + stamp ----
  for (const coll of BUSINESS_COLLECTIONS) {
    const snap = await db.collection(coll).get();
    const numeric = snap.docs.filter((d) => /^\d+$/.test(d.id));
    console.log(`${coll}: ${numeric.length} docs to re-key`);
    if (!APPLY) continue;
    for (const doc of numeric) {
      const data = doc.data();
      data.company_id = companyId;
      data.created_by = data.created_by || createdBy;
      data.created_at = data.created_at || new Date().toISOString();
      await db.collection(coll).doc(`${companyId}_${doc.id}`).set(data);
      await doc.ref.delete();
    }
  }

  // ---- 6. Settings + counters ----
  const settingsDoc = await db.collection('settings').doc('company').get();
  if (settingsDoc.exists) {
    console.log('moving settings/company -> settings/{companyId}');
    if (APPLY) {
      const data = settingsDoc.data();
      delete data.master_reset_code; // legacy local-auth recovery code
      await db.collection('settings').doc(companyId).set(data);
      await settingsDoc.ref.delete();
    }
  }
  const countersDoc = await db.collection('metadata').doc('counters').get();
  if (countersDoc.exists) {
    console.log('moving metadata/counters -> counters/{companyId}');
    if (APPLY) {
      await db.collection('counters').doc(companyId).set({
        company_id: companyId,
        ...countersDoc.data(),
      });
      await countersDoc.ref.delete();
    }
  }

  // ---- 7. Backfill public_quotes for outstanding sent quotes ----
  const quotes = await db.collection('quotes').get();
  let backfilled = 0;
  for (const doc of quotes.docs) {
    const q = doc.data();
    const token = q.access_token;
    if (!token || !['sent', 'viewed'].includes(q.status)) continue;
    backfilled++;
    if (!APPLY) continue;
    const idPart = doc.id.includes('_') ? doc.id.split('_').pop() : doc.id;
    let address = '';
    if (q.property_id != null) {
      const prop = await db.collection('properties').doc(`${companyId}_${q.property_id}`).get();
      if (prop.exists) address = prop.data().address || '';
    }
    await db.collection('public_quotes').doc(token).set({
      company_id: companyId,
      quote_id: Number(idPart),
      status: q.status,
      address,
      quote: q,
      viewed_at: q.viewed_at || null,
      client_signature: q.client_signature || null,
      signed_at: q.signed_at || null,
      client_notes: q.client_notes || null,
      updated_at: new Date().toISOString(),
    });
  }
  console.log(`public_quotes backfilled for ${backfilled} outstanding quotes`);

  // ---- 8. password_reset_requests ----
  const resets = await db.collection('password_reset_requests').get();
  console.log(`password_reset_requests to delete: ${resets.size}`);
  if (APPLY) {
    for (const doc of resets.docs) await doc.ref.delete();
  }

  console.log('done.');
  if (APPLY) {
    console.log(`\nIMPORTANT: record this companyId somewhere safe: ${companyId}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
