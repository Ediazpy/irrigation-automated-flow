/**
 * Firestore security rules tests for IAF.
 *
 * Run with the emulator:
 *   npm test          (uses firebase emulators:exec)
 * or against an already-running emulator (firebase emulators:start --only firestore):
 *   npx mocha --timeout 20000 firestore.rules.test.js
 *
 * Identity model under test: custom claims `role` ('manager' = admin,
 * 'technician' = tech) and `companyId`. Company C1 has a manager and a tech;
 * company C2 exists to prove cross-tenant isolation.
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where } =
  require('firebase/firestore');

const C1 = 'company1';
const C2 = 'company2';

const MANAGER = { uid: 'manager1', claims: { role: 'manager', companyId: C1, email: 'boss@c1.com' } };
const TECH = { uid: 'tech1', claims: { role: 'technician', companyId: C1, email: 'tech@c1.com' } };
const OTHER = { uid: 'outsider', claims: { role: 'manager', companyId: C2, email: 'boss@c2.com' } };

let testEnv;

function db(user) {
  if (!user) return testEnv.unauthenticatedContext().firestore();
  return testEnv.authenticatedContext(user.uid, user.claims).firestore();
}

const stamp = (extra = {}) => ({
  company_id: C1,
  created_by: MANAGER.uid,
  created_at: '2026-01-01T00:00:00.000Z',
  ...extra,
});

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-iaf',
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  // Seed data with rules disabled (as the Admin SDK / migration would)
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    await setDoc(doc(f, 'users', MANAGER.uid), {
      email: 'boss@c1.com', name: 'Boss', role: 'manager',
      is_archived: false, company_id: C1,
    });
    await setDoc(doc(f, 'users', TECH.uid), {
      email: 'tech@c1.com', name: 'Tech', role: 'technician',
      is_archived: false, company_id: C1,
    });
    await setDoc(doc(f, 'clients', `${C1}_1`), stamp({ first_name: 'Alice' }));
    await setDoc(doc(f, 'clients', `${C2}_1`), {
      company_id: C2, created_by: OTHER.uid,
      created_at: '2026-01-01T00:00:00.000Z', first_name: 'Bob',
    });
    await setDoc(doc(f, 'inspections', `${C1}_1`), stamp({
      created_by: TECH.uid, status: 'in_progress',
      technicians: ['tech@c1.com'], property_id: 1,
    }));
    await setDoc(doc(f, 'inspections', `${C1}_2`), stamp({
      status: 'assigned', technicians: ['someoneelse@c1.com'], property_id: 2,
    }));
    await setDoc(doc(f, 'properties', `${C1}_1`), stamp({ address: '1 Main St' }));
    await setDoc(doc(f, 'invoices', `${C1}_1`), stamp({ status: 'draft', total: 100 }));
    await setDoc(doc(f, 'metadata', 'app_version'), { version: '1.0.0' });
    await setDoc(doc(f, 'password_reset_requests', 'boss@c1.com'), { status: 'pending' });
    await setDoc(doc(f, 'public_quotes', 'tok-abc123'), {
      company_id: C1, quote_id: 7, status: 'sent', address: '1 Main St',
      quote: { total_cost: 100 }, updated_at: '2026-01-01T00:00:00.000Z',
    });
  });
});

// ---------- required DENIED cases ----------

describe('unauthenticated access', () => {
  it('denies unauthenticated read of clients', async () => {
    await assertFails(getDoc(doc(db(null), 'clients', `${C1}_1`)));
  });

  it('denies unauthenticated writes to every collection', async () => {
    const f = db(null);
    for (const coll of ['users', 'properties', 'clients', 'inspections',
      'quotes', 'repair_tasks', 'invoices', 'settings', 'counters',
      'metadata', 'password_reset_requests', 'anything_else']) {
      await assertFails(setDoc(doc(f, coll, 'x'), { foo: 'bar' }));
    }
  });
});

describe('company isolation', () => {
  it('denies reading a document from a different companyId', async () => {
    await assertFails(getDoc(doc(db(MANAGER), 'clients', `${C2}_1`)));
    await assertFails(getDoc(doc(db(OTHER), 'clients', `${C1}_1`)));
  });

  it('denies an unscoped collection query', async () => {
    await assertFails(getDocs(collection(db(MANAGER), 'clients')));
  });
});

describe('role restrictions', () => {
  it('denies a tech creating an invoice', async () => {
    await assertFails(setDoc(doc(db(TECH), 'invoices', `${C1}_2`), {
      company_id: C1, created_by: TECH.uid,
      created_at: new Date().toISOString(), status: 'draft', total: 50,
    }));
  });

  it('denies a tech updating or deleting a quote', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'quotes', `${C1}_5`), stamp({ status: 'sent' }));
    });
    await assertFails(updateDoc(doc(db(TECH), 'quotes', `${C1}_5`), { status: 'approved' }));
    await assertFails(deleteDoc(doc(db(TECH), 'quotes', `${C1}_5`)));
  });

  it('denies a user changing their own role field', async () => {
    await assertFails(updateDoc(doc(db(TECH), 'users', TECH.uid), { role: 'manager' }));
  });

  it('denies a user changing their own company or archived flag', async () => {
    await assertFails(updateDoc(doc(db(TECH), 'users', TECH.uid), { company_id: C2 }));
    await assertFails(updateDoc(doc(db(TECH), 'users', TECH.uid), { is_archived: false, role: 'manager' }));
  });

  it('denies a tech reading another user\'s profile', async () => {
    await assertFails(getDoc(doc(db(TECH), 'users', MANAGER.uid)));
  });
});

describe('dead and locked collections', () => {
  it('denies any client read of password_reset_requests', async () => {
    await assertFails(getDoc(doc(db(null), 'password_reset_requests', 'boss@c1.com')));
    await assertFails(getDoc(doc(db(MANAGER), 'password_reset_requests', 'boss@c1.com')));
  });

  it('denies any write to metadata (even managers)', async () => {
    await assertFails(setDoc(doc(db(MANAGER), 'metadata', 'app_version'), { version: '2.0.0' }));
    await assertFails(updateDoc(doc(db(MANAGER), 'metadata', 'app_version'), { version: '2.0.0' }));
  });

  it('denies access to unmatched collections (default deny)', async () => {
    await assertFails(getDoc(doc(db(MANAGER), 'random_collection', 'x')));
    await assertFails(setDoc(doc(db(MANAGER), 'random_collection', 'x'), { a: 1 }));
  });
});

describe('ownership immutability', () => {
  it('denies changing company_id on an existing doc', async () => {
    await assertFails(updateDoc(doc(db(MANAGER), 'clients', `${C1}_1`), { company_id: C2 }));
  });

  it('denies changing created_by on an existing doc', async () => {
    await assertFails(updateDoc(doc(db(MANAGER), 'clients', `${C1}_1`), { created_by: TECH.uid }));
  });

  it('denies creating a doc stamped as someone else', async () => {
    await assertFails(setDoc(doc(db(TECH), 'properties', `${C1}_9`), {
      company_id: C1, created_by: MANAGER.uid,
      created_at: new Date().toISOString(), address: 'Fake',
    }));
  });

  it('denies creating a doc stamped for another company', async () => {
    await assertFails(setDoc(doc(db(TECH), 'properties', `${C2}_9`), {
      company_id: C2, created_by: TECH.uid,
      created_at: new Date().toISOString(), address: 'Fake',
    }));
  });

  it('denies a tech updating an inspection that is not theirs', async () => {
    await assertFails(updateDoc(doc(db(TECH), 'inspections', `${C1}_2`), { status: 'completed' }));
  });

  it('denies hard-deleting an invoice, even as manager', async () => {
    await assertFails(deleteDoc(doc(db(MANAGER), 'invoices', `${C1}_1`)));
  });
});

// ---------- required ALLOWED cases ----------

describe('allowed operations', () => {
  it('allows a tech to read inspections within their own company', async () => {
    await assertSucceeds(getDoc(doc(db(TECH), 'inspections', `${C1}_1`)));
    await assertSucceeds(getDocs(query(
      collection(db(TECH), 'inspections'), where('company_id', '==', C1))));
  });

  it('allows a tech to update an inspection they created', async () => {
    await assertSucceeds(updateDoc(doc(db(TECH), 'inspections', `${C1}_1`),
      { status: 'review' }));
  });

  it('allows a manager to create an invoice in their own company', async () => {
    await assertSucceeds(setDoc(doc(db(MANAGER), 'invoices', `${C1}_2`), {
      company_id: C1, created_by: MANAGER.uid,
      created_at: new Date().toISOString(), status: 'draft', total: 250,
    }));
  });

  it('allows a user to update their own profile name', async () => {
    await assertSucceeds(updateDoc(doc(db(TECH), 'users', TECH.uid), { name: 'New Name' }));
  });

  it('allows a manager to read and edit company users, but not their roles', async () => {
    await assertSucceeds(getDoc(doc(db(MANAGER), 'users', TECH.uid)));
    await assertSucceeds(updateDoc(doc(db(MANAGER), 'users', TECH.uid), { name: 'Renamed' }));
    await assertFails(updateDoc(doc(db(MANAGER), 'users', TECH.uid), { role: 'manager' }));
  });

  it('allows a tech to create a properly stamped property', async () => {
    await assertSucceeds(setDoc(doc(db(TECH), 'properties', `${C1}_2`), {
      company_id: C1, created_by: TECH.uid,
      created_at: new Date().toISOString(), address: '2 Oak Ave',
    }));
  });

  it('allows company members to read settings and counters, managers to write settings', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'settings', C1), { company_name: 'C1 Irrigation' });
      await setDoc(doc(ctx.firestore(), 'counters', C1), { next_property_id: 3 });
    });
    await assertSucceeds(getDoc(doc(db(TECH), 'settings', C1)));
    await assertFails(setDoc(doc(db(TECH), 'settings', C1), { company_name: 'Hacked' }));
    await assertSucceeds(setDoc(doc(db(MANAGER), 'settings', C1), { company_name: 'C1 Irrigation LLC' }));
    await assertSucceeds(setDoc(doc(db(TECH), 'counters', C1), { next_property_id: 4 }));
    await assertFails(getDoc(doc(db(OTHER), 'settings', C1)));
  });

  it('allows a signed-in user to read metadata', async () => {
    await assertSucceeds(getDoc(doc(db(TECH), 'metadata', 'app_version')));
  });
});

// ---------- public quote flow ----------

describe('public_quotes (customer approval by token)', () => {
  it('allows anyone holding the token to fetch the doc, but never to list', async () => {
    await assertSucceeds(getDoc(doc(db(null), 'public_quotes', 'tok-abc123')));
    await assertFails(getDocs(collection(db(null), 'public_quotes')));
  });

  it('allows the customer to approve with signature fields only', async () => {
    await assertSucceeds(updateDoc(doc(db(null), 'public_quotes', 'tok-abc123'), {
      status: 'approved',
      client_signature: 'data:image/png;base64,...',
      signed_at: new Date().toISOString(),
      client_notes: 'Please schedule soon',
      updated_at: new Date().toISOString(),
    }));
  });

  it('denies the customer touching any other field', async () => {
    await assertFails(updateDoc(doc(db(null), 'public_quotes', 'tok-abc123'), {
      status: 'approved',
      quote: { total_cost: 1 },
      updated_at: new Date().toISOString(),
    }));
    await assertFails(updateDoc(doc(db(null), 'public_quotes', 'tok-abc123'), {
      company_id: C2,
    }));
  });

  it('denies re-approving a finalized quote', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'public_quotes', 'tok-abc123'),
        { status: 'approved' });
    });
    await assertFails(updateDoc(doc(db(null), 'public_quotes', 'tok-abc123'), {
      status: 'rejected', updated_at: new Date().toISOString(),
    }));
  });

  it('denies anonymous create and delete of public quotes', async () => {
    await assertFails(setDoc(doc(db(null), 'public_quotes', 'tok-new'), {
      company_id: C1, quote_id: 9, status: 'sent', quote: {},
    }));
    await assertFails(deleteDoc(doc(db(null), 'public_quotes', 'tok-abc123')));
  });

  it('allows only the owning company\'s manager to create mirrors', async () => {
    await assertSucceeds(setDoc(doc(db(MANAGER), 'public_quotes', 'tok-new'), {
      company_id: C1, quote_id: 9, status: 'sent', quote: {}, address: '',
    }));
    await assertFails(setDoc(doc(db(OTHER), 'public_quotes', 'tok-new2'), {
      company_id: C1, quote_id: 9, status: 'sent', quote: {},
    }));
    await assertFails(setDoc(doc(db(TECH), 'public_quotes', 'tok-new3'), {
      company_id: C1, quote_id: 9, status: 'sent', quote: {},
    }));
  });
});
