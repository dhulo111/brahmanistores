import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { headers } from 'next/headers';
import jwt from 'jsonwebtoken';

export async function GET(req) {
  try {
    const headersList = await headers();
    const authorization = headersList.get('authorization');

    if (!authorization || !authorization.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Verify token exists and is valid
    const token = authorization.split(' ')[1];
    const jwtSecret = process.env.JWT_SECRET || 'fallback-secret-for-dev';
    jwt.verify(token, jwtSecret); // Throws if invalid

    const products = await db.product.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        name: true,
        englishName: true,
        price: true,
        isAvailable: true,
        createdAt: true,
      }
    });

    return NextResponse.json({ products });
  } catch (error) {
    console.error('Error fetching products:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
