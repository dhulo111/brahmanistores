import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import path from 'path';
import fs from 'fs';

// Prevent re-initialization in development
if (getApps().length === 0) {
  try {
    const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');
    
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
      
      initializeApp({
        credential: cert(serviceAccount)
      });
      console.log('✅ Firebase Admin initialized successfully');
    } else {
      console.warn('⚠️ firebase-service-account.json not found. Push notifications will be disabled.');
    }
  } catch (error) {
    console.error('🔥 Firebase Admin initialization error:', error);
  }
}

export const sendNotification = async (fcmToken, title, body, data = {}) => {
  if (getApps().length === 0 || !fcmToken) return false;

  try {
    const message = {
      notification: {
        title,
        body,
      },
      data,
      token: fcmToken,
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
