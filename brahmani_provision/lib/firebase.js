import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import path from 'path';
import fs from 'fs';

// Prevent re-initialization in development
if (getApps().length === 0) {
  try {
    let serviceAccount;

    // 1. Try to load from environment variable (For Vercel / Production)
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    } 
    // 2. Fallback to local file (For Local Development)
    else {
      const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');
      if (fs.existsSync(serviceAccountPath)) {
        serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
      }
    }

    if (serviceAccount) {
      initializeApp({
        credential: cert(serviceAccount)
      });
      console.log('✅ Firebase Admin initialized successfully');
    } else {
      console.warn('⚠️ Firebase credentials not found. Push notifications disabled. Set FIREBASE_SERVICE_ACCOUNT_KEY env var.');
    }
  } catch (error) {
    console.error('🔥 Firebase Admin initialization error:', error);
  }
}

export const sendNotification = async (fcmToken, title, body, data = {}, imageUrl = null) => {
  if (getApps().length === 0 || !fcmToken) return false;

  try {
    const notificationPayload = {
      title,
      body,
    };
    if (imageUrl) notificationPayload.imageUrl = imageUrl;

    const message = {
      notification: notificationPayload,
      data,
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel',
          ...(imageUrl && { imageUrl: imageUrl })
        }
      },
      apns: {
        payload: {
          aps: {
            contentAvailable: true,
            sound: 'default'
          }
        }
      }
    };

    const response = await getMessaging().send(message);
    console.log('Successfully sent message:', response);
    return true;
  } catch (error) {
    console.error('Error sending message:', error);
    return false;
  }
};

export const sendAdminNotification = async (title, body, data = {}) => {
  // Ideally, you query all admin users from DB who have an fcmToken
  // For now, this is a placeholder function to be called from the route
  if (getApps().length === 0) return false;
  
  // The route caller should pass the admin tokens to `sendNotification`
  // This helper is just a reminder.
};
