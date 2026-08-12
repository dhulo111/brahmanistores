import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import jwt from 'jsonwebtoken';

export async function PUT(req) {
  try {
    const authHeader = req.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json(
        { error: 'error_unauthorized', message: 'No token provided' },
        { status: 401 }
      );
    }

    const token = authHeader.split(' ')[1];
    const jwtSecret = process.env.JWT_SECRET || 'fallback-secret-for-dev';

    let decoded;
    try {
      decoded = jwt.verify(token, jwtSecret);
    } catch (err) {
      return NextResponse.json(
        { error: 'error_unauthorized', message: 'Invalid or expired token' },
        { status: 401 }
      );
    }

    const body = await req.json();
    const { firstName, lastName, phone } = body;

    if (!firstName || !lastName) {
      return NextResponse.json(
        { error: 'validation_error', message: 'First name and last name are required' },
        { status: 400 }
      );
    }

    const updatedUser = await db.user.update({
      where: {
        id: decoded.userId,
      },
      data: {
        firstName,
        lastName,
        phone: phone || null,
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        avatarUrl: true,
      }
    });

    return NextResponse.json({
      message: 'Profile updated successfully',
      user: updatedUser
    });

  } catch (error) {
    console.error('Profile update error:', error);
    return NextResponse.json(
      { error: 'error_internal_server', message: 'Failed to update profile' },
      { status: 500 }
    );
  }
}
