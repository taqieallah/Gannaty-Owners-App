const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ── Helpers ───────────────────────────────────────────────────────────────────

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/** Fetch all admin FCM tokens from /fcmTokens where role == 'admin' */
async function getAdminTokens() {
  const snap = await db.collection('fcmTokens')
    .where('role', '==', 'admin')
    .get();

  return snap.docs
    .map(d => d.data().token)
    .filter(t => typeof t === 'string' && t.length > 0);
}

/** Fetch the FCM token for a villa's registered client device */
async function getClientToken(villaId) {
  const doc = await db.collection('villas').doc(villaId).get();
  const token = doc.data()?.fcmToken;
  return typeof token === 'string' && token.length > 0 ? token : null;
}

/** Send multicast to a list of tokens, ignoring invalid/stale ones */
async function sendMulticast(tokens, notification, data) {
  if (!tokens.length) return;
  const response = await messaging.sendEachForMulticast({
    tokens,
    notification,
    data,
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
  });

  // Clean up stale tokens that are no longer valid
  const staleTokens = [];
  response.responses.forEach((res, idx) => {
    if (!res.success && res.error?.code === 'messaging/registration-token-not-registered') {
      staleTokens.push(tokens[idx]);
    }
  });
  if (staleTokens.length > 0) {
    const batch = db.batch();
    const snap = await db.collection('fcmTokens')
      .where('token', 'in', staleTokens).get();
    snap.docs.forEach(d => batch.delete(d.ref));
    await batch.commit();
  }
}

/** Send to a single client token */
async function sendToClient(token, notification, data) {
  if (!token) return;
  try {
    await messaging.send({
      token,
      notification,
      data,
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } },
    });
  } catch (err) {
    // Remove stale client token from the villa document
    if (err.code === 'messaging/registration-token-not-registered') {
      const snap = await db.collection('villas')
        .where('fcmToken', '==', token).limit(1).get();
      if (!snap.empty) {
        await snap.docs[0].ref.update({ fcmToken: null });
      }
    }
  }
}

// ── Trigger 1: New service request → notify all admins ───────────────────────

exports.onNewServiceRequest = onDocumentCreated(
  { document: 'serviceRequests/{requestId}', region: 'europe-west1' },
  async (event) => {
    const data = event.data.data();
    const requestId = event.params.requestId;

    const typeLabels = {
      maintenance: 'Maintenance',
      complaint: 'Complaint',
      other: 'Other Request',
    };
    const typeLabel = typeLabels[data.type] || 'New Request';

    const tokens = await getAdminTokens();
    await sendMulticast(
      tokens,
      {
        title: `${typeLabel} – Villa ${data.villaNumber}`,
        body: data.description.length > 100
          ? data.description.substring(0, 97) + '...'
          : data.description,
      },
      {
        screen: 'request_detail',
        id: requestId,
      },
    );
  },
);

// ── Trigger 2: Service request status updated → notify client ─────────────────

exports.onRequestStatusChanged = onDocumentUpdated(
  { document: 'serviceRequests/{requestId}', region: 'europe-west1' },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only fire when status actually changes
    if (before.status === after.status) return;

    const clientToken = await getClientToken(after.villaId);
    if (!clientToken) return;

    const statusMessages = {
      in_progress: { title: 'Request In Progress', body: `Your ${after.type} request is now being handled.` },
      solved:      { title: 'Request Solved ✓',    body: `Your ${after.type} request has been resolved.` },
      pending:     { title: 'Request Update',       body: `Your ${after.type} request status was updated.` },
    };

    const notif = statusMessages[after.status] || statusMessages.pending;

    // Include admin note in body if present
    if (after.adminNote) {
      notif.body += ` Note: ${after.adminNote}`;
    }

    await sendToClient(
      clientToken,
      notif,
      { screen: 'requests' },
    );
  },
);

// ── Trigger 3: New payment assigned → notify client ───────────────────────────

exports.onNewPayment = onDocumentCreated(
  { document: 'payments/{paymentId}', region: 'europe-west1' },
  async (event) => {
    const data = event.data.data();

    const clientToken = await getClientToken(data.villaId);
    if (!clientToken) return;

    const monthName = MONTH_NAMES[(data.month || 1) - 1];
    const formattedAmount = Number(data.amount).toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });

    await sendToClient(
      clientToken,
      {
        title: 'New Payment Due',
        body: `${monthName} ${data.year} – Amount: ${formattedAmount}. Please pay before the due date.`,
      },
      { screen: 'payments' },
    );
  },
);
