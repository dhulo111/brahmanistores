import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import jwt from 'jsonwebtoken';

export async function GET(req) {
  try {
    const authHeader = req.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'error_unauthorized' }, { status: 401 });
    }

    const token = authHeader.split(' ')[1];
    const jwtSecret = process.env.JWT_SECRET || 'fallback-secret-for-dev';
    
    let decoded;
    try {
      decoded = jwt.verify(token, jwtSecret);
    } catch (e) {
      return NextResponse.json({ error: 'error_unauthorized' }, { status: 401 });
    }

    if (decoded.role !== 'ADMIN') {
      return NextResponse.json({ error: 'error_forbidden' }, { status: 403 });
    }

    const pendingUsers = await db.user.findMany({
      where: {
        status: 'PENDING',
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        phone: true,
        avatarUrl: true,
        createdAt: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return NextResponse.json({ users: pendingUsers });
  } catch (error) {
    console.error('Fetch pending users error:', error);
    return NextResponse.json({ error: 'error_internal_server' }, { status: 500 });
  }
}
