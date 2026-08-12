import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { getAuth } from 'firebase-admin/auth';
import jwt from 'jsonwebtoken';
import { getApps } from 'firebase-admin/app';
// We need to ensure firebase is initialized before using getAuth()
import '@/lib/firebase';

export async function POST(req) {
  try {
    const body = await req.json();

    if (!body.idToken) {
      return NextResponse.json({ error: 'idToken is required' }, { status: 400 });
    }

    if (getApps().length === 0) {
      return NextResponse.json({ error: 'Firebase Admin not initialized on server' }, { status: 500 });
    }

    // Verify the Firebase ID token
    let decodedToken;
    try {
      console.log('Verifying idToken:', typeof body.idToken, body.idToken ? body.idToken.substring(0, 20) + '...' : 'null');
      decodedToken = await getAuth().verifyIdToken(body.idToken);
    } catch (verifyError) {
      console.error('Google token verification failed:', verifyError);
      return NextResponse.json({ error: 'error_invalid_token', message: 'Google verification failed' }, { status: 401 });
    }

    const email = decodedToken.email;
    
    if (!email) {
      return NextResponse.json({ error: 'error_invalid_token', message: 'No email found in token' }, { status: 400 });
    }

    // Check if user exists in MongoDB
    const user = await db.user.findFirst({
      where: { email: email }
    });

    if (!user) {
      // User is not registered in our MongoDB yet. 
      // Return 404 with Google data so the client can pre-fill the registration form.
      return NextResponse.json(
        { 
          error: 'error_user_not_found', 
          message: 'Account not found. Please register.',
          googleData: {
            email: email,
            firstName: decodedToken.name ? decodedToken.name.split(' ')[0] : '',
            lastName: decodedToken.name ? decodedToken.name.split(' ').slice(1).join(' ') : '',
            avatarUrl: decodedToken.picture || ''
          }
        },
        { status: 404 }
      );
    }

    // Status check
    if (user.status === 'PENDING') {
      return NextResponse.json(
        { error: 'error_pending_verification', message: 'Your account is pending verification.' },
        { status: 403 }
      );
    }

    if (user.status === 'REJECTED') {
      return NextResponse.json(
        { error: 'error_account_rejected', message: 'Your account registration was rejected.' },
        { status: 403 }
      );
    }

    // Update FCM Token if provided
    if (body.fcmToken) {
      await db.user.update({
        where: { id: user.id },
        data: { fcmToken: body.fcmToken },
      });
    }

    // Issue JWT
    const jwtSecret = process.env.JWT_SECRET || 'fallback-secret-for-dev';
    const token = jwt.sign(
      { 
        userId: user.id,
        email: user.email,
        role: user.role
      },
      jwtSecret,
      { expiresIn: '7d' } // 7 days expiration
    );

    return NextResponse.json({
      message: 'success',
      token,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        avatarUrl: user.avatarUrl,
        role: user.role
      }
    });

  } catch (error) {
    console.error('Google Login error:', error);
    return NextResponse.json(
      { error: 'error_internal_server' },
      { status: 500 }
    );
  }
}
