import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import jwt from 'jsonwebtoken';

export async function GET(req, { params }) {
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

    const { id } = await params; // userId

    if (!id) {
      return NextResponse.json({ error: 'invalid_request' }, { status: 400 });
    }

    const user = await db.user.findUnique({
      where: { id },
      select: { id: true, firstName: true, lastName: true, balance: true }
    });
    
    if (!user) {
      return NextResponse.json({ error: 'user_not_found' }, { status: 404 });
    }

    const transactions = await db.transaction.findMany({
      where: { userId: id },
      orderBy: { createdAt: 'desc' }
    });

    return NextResponse.json({ user, transactions });
  } catch (error) {
    console.error('Get transactions error:', error);
    return NextResponse.json({ error: 'error_internal_server' }, { status: 500 });
  }
}
