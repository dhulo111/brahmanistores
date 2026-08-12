import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { loginSchema } from '@/lib/validations/auth';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

export async function POST(req) {
  try {
    const body = await req.json();

    // Validate using Zod
    const validationResult = loginSchema.safeParse(body);

    if (!validationResult.success) {
      return NextResponse.json(
        { error: 'validation_error', details: validationResult.error.errors },
        { status: 400 }
      );
    }

    const { emailOrUsername, password } = validationResult.data;

    // Find user (assuming username is just email for now based on schema)
    const user = await db.user.findFirst({
      where: {
        email: emailOrUsername,
      }
    });

    if (!user) {
      return NextResponse.json(
        { error: 'error_invalid_credentials' },
        { status: 401 }
      );
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      return NextResponse.json(
        { error: 'error_invalid_credentials' },
        { status: 401 }
      );
    }

    // Role check for admin apps
    if (body.roleRequired && body.roleRequired === 'ADMIN' && user.role !== 'ADMIN') {
      return NextResponse.json(
        { error: 'error_unauthorized', message: 'Admin access required.' },
        { status: 403 }
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
    console.error('Login error:', error);
    return NextResponse.json(
      { error: 'error_internal_server' },
      { status: 500 }
    );
  }
}
