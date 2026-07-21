/**
 * IAF identity functions.
 *
 * Role and companyId live as custom claims on the Firebase Auth ID token —
 * signed by Google, unforgeable by the client. Firestore user documents are
 * profile data only. All privileged mutations (user creation, role changes,
 * archiving) happen here via the Admin SDK, which bypasses security rules
 * by design, so every function must verify the caller itself.
 */
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

admin.initializeApp();

const VALID_ROLES = ['manager', 'technician'];

function requireAuth(req) {
  if (!req.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  return req.auth;
}

function requireManager(req) {
  const auth = requireAuth(req);
  if (auth.token.role !== 'manager' || !auth.token.companyId) {
    throw new HttpsError('permission-denied', 'Manager access required.');
  }
  return auth;
}

/**
 * First-time company signup. The caller has just created their Firebase Auth
 * account client-side; this assigns them a fresh companyId + manager role and
 * creates the profile/settings/counters documents server-side.
 */
exports.bootstrapCompany = onCall(async (req) => {
  const auth = requireAuth(req);

  // An account that already belongs to a company must not mint a new one.
  if (auth.token.companyId) {
    throw new HttpsError('failed-precondition', 'Account already belongs to a company.');
  }

  const companyName = String(req.data?.companyName || '').trim();
  const name = String(req.data?.name || '').trim();
  if (!companyName || !name) {
    throw new HttpsError('invalid-argument', 'companyName and name are required.');
  }

  const db = admin.firestore();
  const companyId = db.collection('settings').doc().id;
  const now = new Date().toISOString();

  await admin.auth().setCustomUserClaims(auth.uid, {
    role: 'manager',
    companyId,
  });

  const batch = db.batch();
  batch.set(db.collection('users').doc(auth.uid), {
    email: (auth.token.email || '').toLowerCase(),
    name,
    role: 'manager',
    is_archived: false,
    company_id: companyId,
    created_by: auth.uid,
    created_at: now,
  });
  batch.set(db.collection('settings').doc(companyId), {
    company_name: companyName,
  });
  batch.set(db.collection('counters').doc(companyId), {
    company_id: companyId,
    next_property_id: 1,
    next_inspection_id: 1,
    next_quote_id: 1,
    next_repair_task_id: 1,
    next_client_id: 1,
    next_invoice_id: 1,
  });
  await batch.commit();

  return { companyId };
});

/**
 * Manager-only: create a user inside the caller's company.
 * Claims are set before the new user can ever sign in.
 */
exports.createUser = onCall(async (req) => {
  const auth = requireManager(req);
  const companyId = auth.token.companyId;

  const email = String(req.data?.email || '').trim().toLowerCase();
  const password = String(req.data?.password || '');
  const name = String(req.data?.name || '').trim();
  const role = String(req.data?.role || '');

  if (!email || !email.includes('@') || !name) {
    throw new HttpsError('invalid-argument', 'Valid email and name are required.');
  }
  if (!VALID_ROLES.includes(role)) {
    throw new HttpsError('invalid-argument', `role must be one of: ${VALID_ROLES.join(', ')}`);
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }

  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });
  } catch (e) {
    if (e.code === 'auth/email-already-exists') {
      throw new HttpsError('already-exists', 'An account with this email already exists.');
    }
    throw new HttpsError('internal', 'Could not create the account.');
  }

  await admin.auth().setCustomUserClaims(userRecord.uid, { role, companyId });

  await admin.firestore().collection('users').doc(userRecord.uid).set({
    email,
    name,
    role,
    is_archived: false,
    company_id: companyId,
    created_by: auth.uid,
    created_at: new Date().toISOString(),
  });

  return { uid: userRecord.uid };
});

/** Load a target user's profile and verify it belongs to the caller's company. */
async function getCompanyUser(uid, companyId) {
  const doc = await admin.firestore().collection('users').doc(uid).get();
  if (!doc.exists || doc.data().company_id !== companyId) {
    throw new HttpsError('not-found', 'User not found in your company.');
  }
  return doc.data();
}

/**
 * Manager-only: change another user's role. Refuses self-changes so a company
 * can't demote its only manager by accident.
 */
exports.setUserRole = onCall(async (req) => {
  const auth = requireManager(req);
  const uid = String(req.data?.uid || '');
  const role = String(req.data?.role || '');

  if (!VALID_ROLES.includes(role)) {
    throw new HttpsError('invalid-argument', `role must be one of: ${VALID_ROLES.join(', ')}`);
  }
  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }
  if (uid === auth.uid) {
    throw new HttpsError('failed-precondition', 'You cannot change your own role.');
  }

  await getCompanyUser(uid, auth.token.companyId);

  await admin.auth().setCustomUserClaims(uid, {
    role,
    companyId: auth.token.companyId,
  });
  // Revoke tokens so the old role stops working at next token refresh
  await admin.auth().revokeRefreshTokens(uid);
  await admin.firestore().collection('users').doc(uid).update({ role });

  return { ok: true };
});

/**
 * Manager-only: archive (disable sign-in) or unarchive a user.
 */
exports.setUserArchived = onCall(async (req) => {
  const auth = requireManager(req);
  const uid = String(req.data?.uid || '');
  const archived = Boolean(req.data?.archived);

  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }
  if (uid === auth.uid) {
    throw new HttpsError('failed-precondition', 'You cannot archive your own account.');
  }

  await getCompanyUser(uid, auth.token.companyId);

  await admin.auth().updateUser(uid, { disabled: archived });
  if (archived) {
    await admin.auth().revokeRefreshTokens(uid);
  }
  await admin.firestore().collection('users').doc(uid).update({ is_archived: archived });

  return { ok: true };
});

// ---------------------------------------------------------------------------
// Recurring inspection scheduler
// ---------------------------------------------------------------------------

const FREQUENCY_MONTHS = { monthly: 1, quarterly: 3, semiannual: 6 };

function monthKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
}

function monthsBetween(fromKey, toKey) {
  const [fy, fm] = fromKey.split('-').map(Number);
  const [ty, tm] = toKey.split('-').map(Number);
  return (ty - fy) * 12 + (tm - fm);
}

/**
 * Runs every morning. For each property whose inspection interval has
 * elapsed (and whose billing-cycle day has arrived), creates a "due"
 * inspection in the owning company. Due inspections appear on the manager's
 * "To Schedule" list; assigning a date and team member moves them to
 * "assigned". One-time properties are never auto-scheduled.
 */
exports.generateDueInspections = onSchedule(
  { schedule: 'every day 05:00', timeZone: 'America/Chicago' },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const currentMonth = monthKey(now);

    const properties = await db.collection('properties').get();
    let created = 0;

    for (const doc of properties.docs) {
      const p = doc.data();
      const frequency = p.inspection_frequency || 'monthly';
      const interval = FREQUENCY_MONTHS[frequency];
      if (!interval) continue; // one_time or unknown — never auto-schedule

      const companyId = p.company_id;
      if (!companyId) continue; // unmigrated/legacy doc

      // Interval elapsed since the last generated month?
      const last = p.last_scheduled_month;
      if (last && monthsBetween(last, currentMonth) < interval) continue;

      // Wait for the property's billing-cycle day
      const cycleDay = Number(p.billing_cycle_day) || 1;
      if (now.getDate() < cycleDay) continue;

      // Extract the numeric property id from the doc id ({companyId}_{n})
      const idPart = doc.id.includes('_') ? doc.id.split('_').pop() : doc.id;
      const propertyId = Number(idPart);
      if (!Number.isFinite(propertyId)) continue;

      // Skip if this month's inspection already exists (manually created or
      // from an earlier run)
      const existing = await db.collection('inspections')
        .where('company_id', '==', companyId)
        .where('property_id', '==', propertyId)
        .where('billing_month', '==', currentMonth)
        .limit(1)
        .get();
      if (!existing.empty) {
        await doc.ref.update({ last_scheduled_month: currentMonth });
        continue;
      }

      // Allocate the next inspection id from the company's counters
      const counterRef = db.collection('counters').doc(companyId);
      const inspectionId = await db.runTransaction(async (tx) => {
        const counter = await tx.get(counterRef);
        const nextId = (counter.data() || {}).next_inspection_id || 1;
        tx.set(counterRef, { next_inspection_id: nextId + 1 }, { merge: true });
        return nextId;
      });

      await db.collection('inspections').doc(`${companyId}_${inspectionId}`).set({
        property_id: propertyId,
        technicians: [],
        date: '',
        status: 'due',
        repairs: [],
        other_repairs: [],
        other_notes: '',
        total_cost: 0,
        billing_month: currentMonth,
        labor_cost: 0,
        discount: 0,
        tax: 0,
        zone_photos: {},
        company_id: companyId,
        created_by: 'scheduler',
        created_at: now.toISOString(),
      });
      await doc.ref.update({ last_scheduled_month: currentMonth });
      created++;
    }

    console.log(`generateDueInspections: created ${created} due inspection(s) for ${currentMonth}`);
  });
