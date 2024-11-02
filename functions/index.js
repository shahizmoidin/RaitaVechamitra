/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendScheduledNotifications = functions.pubsub.schedule('every 1 minutes').onRun(async (context) => {
    const currentTimestamp = new Date();
    const snapshot = await admin.firestore().collection('scheduled_notifications')
        .where('timestamp', '<=', currentTimestamp.toISOString())
        .get();

    const messages = [];

    snapshot.forEach(doc => {
        const notification = doc.data();
        messages.push({
            notification: {
                title: 'Scheduled Reminder',
                body: notification.message,
            },
            token: notification.fcmToken,
        });

        admin.firestore().collection('scheduled_notifications').doc(doc.id).delete();
    });

    if (messages.length > 0) {
        await admin.messaging().sendAll(messages);
        console.log('Notifications sent');
    } else {
        console.log('No notifications to send');
    }
});
