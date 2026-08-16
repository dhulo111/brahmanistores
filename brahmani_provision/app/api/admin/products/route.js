import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { headers } from 'next/headers';
import jwt from 'jsonwebtoken';

async function verifyAdmin() {
  const headersList = await headers();
  const authorization = headersList.get('authorization');

  if (!authorization || !authorization.startsWith('Bearer ')) {
    return null;
  }

  try {
    const token = authorization.split(' ')[1];
    const jwtSecret = process.env.JWT_SECRET || 'fallback-secret-for-dev';
    const decoded = jwt.verify(token, jwtSecret);

    if (decoded.role !== 'ADMIN') {
      return null;
    }

    return decoded;
  } catch (e) {
    return null;
  }
}

export async function POST(req) {
  const adminUser = await verifyAdmin();
  if (!adminUser) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const body = await req.json();

    const product = await db.product.create({
      data: {
        name: body.name,
        englishName: body.englishName,
        price: parseFloat(body.price),
        isAvailable: body.isAvailable ?? true,
      },
    });

    return NextResponse.json({ message: 'Product created', product }, { status: 201 });
  } catch (error) {
    console.error('Error creating product:', error);
    return NextResponse.json({ error: 'Failed to create product' }, { status: 500 });
  }
}
