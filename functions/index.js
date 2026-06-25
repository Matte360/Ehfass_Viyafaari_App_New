const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

admin.initializeApp();

exports.sendPushForNotification = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const notification = event.data?.data();
    if (!notification) return;

    const userId = notification.userId;
    if (!userId) return;

    const userSnapshot = await admin.firestore().collection('users').doc(userId).get();
    if (!userSnapshot.exists) return;

    const user = userSnapshot.data() || {};
    const tokens = Array.isArray(user.fcmTokens)
      ? user.fcmTokens.filter((token) => typeof token === 'string' && token.length > 0)
      : [];

    if (tokens.length === 0) return;

    const message = {
      tokens,
      notification: {
        title: String(notification.title || 'Viyafaari Town'),
        body: String(notification.body || 'You have a new update.'),
      },
      data: {
        type: String(notification.type || ''),
        businessId: String(notification.businessId || ''),
        orderId: String(notification.orderId || ''),
        quotationId: String(notification.quotationId || ''),
        chatThreadId: String(notification.chatThreadId || ''),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'viyafaari_updates',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    const failedTokens = [];
    response.responses.forEach((result, index) => {
      if (!result.success) failedTokens.push(tokens[index]);
    });

    if (failedTokens.length > 0) {
      await userSnapshot.ref.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens),
      });
    }
  }
);
