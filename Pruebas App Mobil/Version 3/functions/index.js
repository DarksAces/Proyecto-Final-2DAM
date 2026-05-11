const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Sends a customized push notification and saves it to the GLOBAL notifications collection.
 * Supports deep linking to the specific chat.
 */
exports.onMessageSent = functions.firestore
    .document('chats/{chatId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const chatId = context.params.chatId;

        try {
            // 1. Get chat details to find participants
            const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
            if (!chatDoc.exists) return null;
            
            const participants = chatDoc.data().participants;
            
            // 2. Identify the recipient and the sender
            const recipientId = participants.find(id => id !== message.senderId);
            const senderId = message.senderId;
            if (!recipientId || !senderId) return null;

            // 3. Fetch SENDER's name
            const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
            const senderName = senderDoc.exists ? (senderDoc.data().userName || senderDoc.data().fullName || 'Alguien') : 'Alguien';

            // 4. Save notification to GLOBAL collection (matches UserService.getNotifications)
            let historyText = message.text;
            if (message.type === 'image') historyText = '📷 Te ha enviado una imagen';
            if (message.type === 'video') historyText = '🎥 Te ha enviado un vídeo';
            if (message.type === 'post_share') historyText = '📍 Ha compartido una publicación';

            await admin.firestore()
                .collection('notifications') // Root collection to match app logic
                .add({
                    userId: recipientId, // Required by app filter
                    type: 'chat',
                    message: `${senderName}: ${historyText}`,
                    chatId: chatId,
                    senderId: senderId,
                    read: false,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });

            // 5. Retrieve recipient's FCM Token for PUSH
            const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
            if (!userDoc.exists) return null;
            
            const fcmToken = userDoc.data().fcmToken;

            if (fcmToken) {
                // 6. Build the notification payload with chatId for Deep Linking
                const payload = {
                    token: fcmToken,
                    notification: {
                        title: `Mensaje de ${senderName}`,
                        body: historyText,
                    },
                    data: {
                        chatId: chatId,
                        type: 'chat',
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                    android: {
                        priority: 'high',
                        notification: {
                            channelId: 'high_importance_channel',
                            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                        }
                    }
                };
                
                await admin.messaging().send(payload);
                console.log(`Final Deep-link notification sent to ${recipientId}`);
            }
        } catch (error) {
            console.error('Error in final onMessageSent function:', error);
        }
        
        return null;
    });
